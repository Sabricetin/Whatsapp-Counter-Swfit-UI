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
    
    private var savedAnalyses: [SavedAnalysis] = []
    private var savedMediaAnalyses: [SavedMediaAnalysis] = []
    
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
                    try? fileManager.removeItem(at: url)
                }
            }
        } catch {
            logger.error("Failed to list media directory contents: \(error.localizedDescription)")
        }
    }
    
    func saveAnalysis(_ analysis: AnalysisSummary, fileName: String) throws {
        var savedAnalyses = getSavedAnalyses()
        
        let savedAnalysis = SavedAnalysis(
            id: UUID(),
            fileName: fileName,
            date: Date(),
            analysis: analysis
        )
        
        if let index = savedAnalyses.firstIndex(where: { $0.fileName == fileName }) {
            savedAnalyses[index] = savedAnalysis
        } else {
            savedAnalyses.insert(savedAnalysis, at: 0)
        }
        
        do {
            let encoded = try JSONEncoder().encode(savedAnalyses)
            defaults.set(encoded, forKey: storageKey)
            defaults.synchronize()
            saveLastSelectedAnalysis(savedAnalysis)
        } catch {
            logger.error("Failed to save analysis: \(error.localizedDescription)")
            throw AnalysisStorageError.encodingError
        }
    }
    
    func saveMediaAnalysis(_ mediaStats: MediaStats, fileName: String) throws {
        var savedMediaAnalyses = getSavedMediaAnalyses()
        
        // Yeni medya analizi için benzersiz ID oluştur
        let savedMediaAnalysis = SavedMediaAnalysis(
            id: UUID(),
            fileName: fileName,
            date: Date(),
            mediaStats: mediaStats
        )
        
        // Aynı dosya adına sahip analiz varsa güncelle, yoksa yeni ekle
        if let index = savedMediaAnalyses.firstIndex(where: { $0.fileName == fileName }) {
            savedMediaAnalyses[index] = savedMediaAnalysis
        } else {
            savedMediaAnalyses.insert(savedMediaAnalysis, at: 0)
        }
        
        do {
            let encoded = try JSONEncoder().encode(savedMediaAnalyses)
            defaults.set(encoded, forKey: mediaStorageKey)
            defaults.synchronize()
            
            // Son seçilen medya analizini güncelle
            saveLastSelectedMediaAnalysis(savedMediaAnalysis)
        } catch {
            logger.error("Failed to save media analysis: \(error.localizedDescription)")
            throw AnalysisStorageError.encodingError
        }
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
    
    func loadSavedAnalyses() throws {
        let data = defaults.data(forKey: storageKey) ?? Data()
        savedAnalyses = try JSONDecoder().decode([SavedAnalysis].self, from: data)
    }
    
    func loadSavedMediaAnalyses() throws {
        let data = defaults.data(forKey: mediaStorageKey) ?? Data()
        savedMediaAnalyses = try JSONDecoder().decode([SavedMediaAnalysis].self, from: data)
    }
} 