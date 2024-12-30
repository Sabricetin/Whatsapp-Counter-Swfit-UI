import Foundation
import OSLog

enum AnalysisStorageError: Error {
    case encodingError
    case decodingError
    case fileSystemError
    case invalidData
}

class AnalysisStorage {
    private let defaults = UserDefaults.standard
    private let storageKey = "saved_analyses"
    private let mediaStorageKey = "saved_media_analyses"
    private let lastAnalysisKey = "last_selected_analysis"
    private let lastMediaAnalysisKey = "last_selected_media_analysis"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WhatsApp-Counter", category: "AnalysisStorage")
    
    private var mediaDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("MediaAnalysis", isDirectory: true)
    }
    
    init() {
        createMediaDirectory()
    }
    
    private func createMediaDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: mediaDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            cleanupOrphanedMediaFiles()
        } catch {
            logger.error("Failed to create media directory: \(error.localizedDescription)")
        }
    }
    
    private func cleanupOrphanedMediaFiles() {
        let fileManager = FileManager.default
        let savedAnalyses = getSavedMediaAnalyses()
        let validDirectories = Set(savedAnalyses.map { $0.id.uuidString })
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: mediaDirectory,
                includingPropertiesForKeys: nil
            )
            
            for url in contents {
                let dirname = url.lastPathComponent
                if !validDirectories.contains(dirname) {
                    do {
                        try fileManager.removeItem(at: url)
                        logger.info("Removed orphaned directory: \(dirname)")
                    } catch {
                        logger.error("Failed to remove orphaned directory: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            logger.error("Failed to list media directory contents: \(error.localizedDescription)")
        }
    }
    
    func validateMediaFiles(_ analysis: SavedMediaAnalysis) -> SavedMediaAnalysis {
        let fileManager = FileManager.default
        var updatedStats = analysis.mediaStats
        var hasChanges = false
        
        let originalCount = updatedStats.mediaFiles.count
        updatedStats.mediaFiles = updatedStats.mediaFiles.filter { file in
            let exists = fileManager.fileExists(atPath: file.url.path)
            if !exists {
                logger.warning("Media file not found: \(file.url.path)")
                hasChanges = true
            }
            return exists
        }
        
        if hasChanges {
            logger.info("Removed \(originalCount - updatedStats.mediaFiles.count) invalid media files")
            
            updatedStats.totalImages = updatedStats.mediaFiles.filter { $0.type == .image }.count
            updatedStats.totalGifs = updatedStats.mediaFiles.filter { $0.type == .gif }.count
            updatedStats.totalVideos = updatedStats.mediaFiles.filter { $0.type == .video }.count
            updatedStats.totalSize = updatedStats.mediaFiles.reduce(0) { $0 + $1.size }
            
            var mediaByParticipant: [String: ParticipantMediaStats] = [:]
            let participantFiles = Dictionary(grouping: updatedStats.mediaFiles) { $0.participant }
            
            for (participant, files) in participantFiles {
                let participantImages = files.filter { $0.type == .image }.count
                let participantGifs = files.filter { $0.type == .gif }.count
                let participantVideos = files.filter { $0.type == .video }.count
                let participantSize = files.reduce(0) { $0 + $1.size }
                
                let fileTypes = Dictionary(grouping: files) { $0.fileExtension }
                    .mapValues { $0.count }
                
                mediaByParticipant[participant] = ParticipantMediaStats(
                    imageCount: participantImages,
                    gifCount: participantGifs,
                    videoCount: participantVideos,
                    totalSize: participantSize,
                    averageMediaPerDay: Double(files.count),
                    mostActiveMediaDays: [],
                    fileTypes: fileTypes
                )
            }
            
            updatedStats.mediaByParticipant = mediaByParticipant
            
            let calendar = Calendar.current
            var dailyStats: [DailyMediaStats] = []
            var monthlyStats: [MonthlyMediaStats] = []
            
            let groupedByDay = Dictionary(grouping: updatedStats.mediaFiles) { file in
                calendar.startOfDay(for: file.creationDate ?? Date())
            }
            
            for (date, files) in groupedByDay {
                let dayStats = DailyMediaStats(
                    date: date,
                    imageCount: files.filter { $0.type == .image }.count,
                    gifCount: files.filter { $0.type == .gif }.count,
                    videoCount: files.filter { $0.type == .video }.count,
                    totalSize: files.reduce(0) { $0 + $1.size }
                )
                dailyStats.append(dayStats)
            }
            
            let groupedByMonth = Dictionary(grouping: updatedStats.mediaFiles) { file in
                let date = file.creationDate ?? Date()
                return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
            }
            
            for (month, files) in groupedByMonth {
                let daysInMonth = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
                let monthStats = MonthlyMediaStats(
                    month: month,
                    imageCount: files.filter { $0.type == .image }.count,
                    gifCount: files.filter { $0.type == .gif }.count,
                    videoCount: files.filter { $0.type == .video }.count,
                    totalSize: files.reduce(0) { $0 + $1.size },
                    averagePerDay: Double(files.count) / Double(daysInMonth)
                )
                monthlyStats.append(monthStats)
            }
            
            updatedStats.dailyMediaStats = dailyStats.sorted { $0.date < $1.date }
            updatedStats.monthlyMediaStats = monthlyStats.sorted { $0.month < $1.month }
            
            updatedStats.fileTypes = Dictionary(grouping: updatedStats.mediaFiles) { $0.fileExtension }
                .mapValues { $0.count }
        }
        
        return SavedMediaAnalysis(
            id: analysis.id,
            fileName: analysis.fileName,
            date: analysis.date,
            mediaStats: updatedStats
        )
    }
    
    func saveAnalysis(_ analysis: AnalysisSummary, fileName: String) throws {
        var savedAnalyses = getSavedAnalyses()
        let newAnalysis = SavedAnalysis(
            id: UUID(),
            fileName: fileName,
            date: Date(),
            analysis: analysis
        )
        savedAnalyses.append(newAnalysis)
        
        do {
            let encoded = try JSONEncoder().encode(savedAnalyses)
            defaults.set(encoded, forKey: storageKey)
        } catch {
            logger.error("Failed to save analysis: \(error.localizedDescription)")
            throw AnalysisStorageError.encodingError
        }
    }
    
    func saveMediaAnalysis(_ mediaStats: MediaStats, fileName: String) throws {
        var savedMediaAnalyses = getSavedMediaAnalyses()
        
        let newAnalysis = SavedMediaAnalysis(
            id: UUID(),
            fileName: fileName,
            date: Date(),
            mediaStats: mediaStats
        )
        
        if let index = savedMediaAnalyses.firstIndex(where: { $0.fileName == fileName }) {
            savedMediaAnalyses[index] = newAnalysis
        } else {
            savedMediaAnalyses.append(newAnalysis)
        }
        
        let encoded = try JSONEncoder().encode(savedMediaAnalyses)
        defaults.set(encoded, forKey: mediaStorageKey)
        defaults.synchronize()
    }
    
    func getSavedAnalyses() -> [SavedAnalysis] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let analyses = try JSONDecoder().decode([SavedAnalysis].self, from: data)
            return analyses.sorted { $0.date > $1.date }
        } catch {
            logger.error("Failed to decode saved analyses: \(error.localizedDescription)")
            return []
        }
    }
    
    func getSavedMediaAnalyses() -> [SavedMediaAnalysis] {
        guard let data = defaults.data(forKey: mediaStorageKey) else {
            return []
        }
        
        do {
            let analyses = try JSONDecoder().decode([SavedMediaAnalysis].self, from: data)
            return analyses.sorted { $0.date > $1.date }
        } catch {
            logger.error("Failed to decode saved media analyses: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteAnalysis(id: UUID) throws {
        var savedAnalyses = getSavedAnalyses()
        savedAnalyses.removeAll { $0.id == id }
        
        do {
            let encoded = try JSONEncoder().encode(savedAnalyses)
            defaults.set(encoded, forKey: storageKey)
        } catch {
            logger.error("Failed to delete analysis: \(error.localizedDescription)")
            throw AnalysisStorageError.encodingError
        }
    }
    
    func deleteMediaAnalysis(id: UUID) throws {
        // 1. Mevcut analizleri al
        var savedMediaAnalyses = getSavedMediaAnalyses()
        
        // 2. Silinecek analizin indexini bul
        guard let indexToDelete = savedMediaAnalyses.firstIndex(where: { $0.id == id }) else {
            return // Silinecek analiz bulunamadıysa çık
        }
        
        // 3. Sadece o indexdeki analizi sil
        savedMediaAnalyses.remove(at: indexToDelete)
        
        // 4. Güncellenmiş listeyi kaydet
        let encoded = try JSONEncoder().encode(savedMediaAnalyses)
        defaults.set(encoded, forKey: mediaStorageKey)
        defaults.synchronize()
        
        // 5. Eğer silinen analiz son seçilen analizse, onu da temizle
        if let lastSelectedData = defaults.data(forKey: lastMediaAnalysisKey),
           let lastSelected = try? JSONDecoder().decode(SavedMediaAnalysis.self, from: lastSelectedData),
           lastSelected.id == id {
            defaults.removeObject(forKey: lastMediaAnalysisKey)
            defaults.synchronize()
        }
    }
    
    func getLatestMediaAnalysis() -> MediaStats? {
        return getSavedMediaAnalyses().first?.mediaStats
    }
    
    func saveLastSelectedAnalysis(_ analysis: SavedAnalysis) {
        if let encoded = try? JSONEncoder().encode(analysis) {
            defaults.set(encoded, forKey: lastAnalysisKey)
        }
    }
    
    func saveLastSelectedMediaAnalysis(_ analysis: SavedMediaAnalysis) {
        if let encoded = try? JSONEncoder().encode(analysis) {
            defaults.set(encoded, forKey: lastMediaAnalysisKey)
        }
        
        var savedMediaAnalyses = getSavedMediaAnalyses()
        if let index = savedMediaAnalyses.firstIndex(where: { $0.fileName == analysis.fileName }) {
            savedMediaAnalyses[index] = analysis
            if let encoded = try? JSONEncoder().encode(savedMediaAnalyses) {
                defaults.set(encoded, forKey: mediaStorageKey)
            }
        }
    }
    
    func getLastSelectedAnalysis() -> SavedAnalysis? {
        guard let data = defaults.data(forKey: lastAnalysisKey),
              let analysis = try? JSONDecoder().decode(SavedAnalysis.self, from: data) else {
            return nil
        }
        return analysis
    }
    
    func getLastSelectedMediaAnalysis() -> SavedMediaAnalysis? {
        guard let data = defaults.data(forKey: lastMediaAnalysisKey),
              let analysis = try? JSONDecoder().decode(SavedMediaAnalysis.self, from: data) else {
            return nil
        }
        return analysis
    }
    
    func clearLastSelectedAnalysis() {
        defaults.removeObject(forKey: lastAnalysisKey)
    }
    
    func clearLastSelectedMediaAnalysis() {
        defaults.removeObject(forKey: lastMediaAnalysisKey)
    }
} 