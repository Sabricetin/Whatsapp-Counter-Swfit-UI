import Foundation
import ZIPFoundation
import OSLog

enum MediaAnalyzerError: Error {
    case fileReadError
    case zipExtractionError
    case noMediaFound
    case invalidFormat
}

class MediaAnalyzer {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WhatsApp-Counter", category: "MediaAnalyzer")
    private let calendar = Calendar.current
    
    private var mediaDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("MediaAnalysis", isDirectory: true)
    }
    
    init() {
        try? FileManager.default.createDirectory(
            at: mediaDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    func analyzeMediaZip(at url: URL) async throws -> MediaStats {
        logger.info("Starting media analysis of file: \(url.lastPathComponent)")
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let analysisId = UUID().uuidString
        let mediaDir = mediaDirectory.appendingPathComponent(analysisId)
        
        let chatName = url.deletingPathExtension().lastPathComponent
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(at: mediaDir, withIntermediateDirectories: true, attributes: nil)
            
            defer {
                try? fileManager.removeItem(at: tempDir)
            }
            
            try fileManager.unzipItem(at: url, to: tempDir)
            
            let mediaFiles = try await findAndCopyMediaFiles(from: tempDir, to: mediaDir)
            guard !mediaFiles.isEmpty else {
                try? fileManager.removeItem(at: mediaDir)
                throw MediaAnalyzerError.noMediaFound
            }
            
            var stats = try await generateStats(from: mediaFiles)
            stats.chatName = chatName
            return stats
            
        } catch {
            try? fileManager.removeItem(at: mediaDir)
            logger.error("Failed to process media ZIP: \(error.localizedDescription)")
            throw MediaAnalyzerError.zipExtractionError
        }
    }
    
    private func findAndCopyMediaFiles(from sourceDir: URL, to targetDir: URL) async throws -> [MediaFile] {
        let fileManager = FileManager.default
        var mediaFiles: [MediaFile] = []
        
        if let enumerator = fileManager.enumerator(
            at: sourceDir,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let mediaType = MediaType.detect(from: fileURL.pathExtension)
                guard mediaType != .unknown else { continue }
                
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
                    let size = Int64(resourceValues.fileSize ?? 0)
                    let creationDate = resourceValues.creationDate
                    
                    let filename = fileURL.lastPathComponent
                    let participant = extractParticipant(from: filename)
                    
                    let newFilename = "\(UUID().uuidString)-\(participant).\(fileURL.pathExtension)"
                    let targetURL = targetDir.appendingPathComponent(newFilename)
                    try fileManager.copyItem(at: fileURL, to: targetURL)
                    
                    let mediaFile = MediaFile(
                        url: targetURL,
                        type: mediaType,
                        size: size,
                        creationDate: creationDate,
                        participant: participant
                    )
                    mediaFiles.append(mediaFile)
                } catch {
                    logger.error("Error processing file: \(error.localizedDescription)")
                    continue
                }
            }
        }
        
        return mediaFiles
    }
    
    private func extractParticipant(from filename: String) -> String {
        if let range = filename.range(of: " - ") {
            let participant = String(filename[range.upperBound...])
                .replacingOccurrences(of: ".[^.]+$", with: "", options: .regularExpression)
            return participant.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Bilinmeyen"
    }
    
    private func generateStats(from mediaFiles: [MediaFile]) async throws -> MediaStats {
        var participantStats: [String: ParticipantMediaStats] = [:]
        var dailyStats: [Date: (images: Int, gifs: Int, videos: Int, size: Int64)] = [:]
        var monthlyStats: [Date: (images: Int, gifs: Int, videos: Int, size: Int64)] = [:]
        var fileTypes: [String: Int] = [:]
        
        var totalImages = 0
        var totalGifs = 0
        var totalVideos = 0
        var totalSize: Int64 = 0
        
        for file in mediaFiles {
            fileTypes[file.fileExtension, default: 0] += 1
            
            switch file.type {
            case .image:
                totalImages += 1
            case .gif:
                totalGifs += 1
            case .video:
                totalVideos += 1
            case .unknown:
                continue
            }
            
            totalSize += file.size
            
            if let date = file.creationDate {
                let dayStart = calendar.startOfDay(for: date)
                
                if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) {
                    var dayStats = dailyStats[dayStart] ?? (images: 0, gifs: 0, videos: 0, size: 0)
                    switch file.type {
                    case .image:
                        dayStats.images += 1
                    case .gif:
                        dayStats.gifs += 1
                    case .video:
                        dayStats.videos += 1
                    case .unknown:
                        break
                    }
                    dayStats.size += file.size
                    dailyStats[dayStart] = dayStats
                    
                    var monthStats = monthlyStats[monthStart] ?? (images: 0, gifs: 0, videos: 0, size: 0)
                    switch file.type {
                    case .image:
                        monthStats.images += 1
                    case .gif:
                        monthStats.gifs += 1
                    case .video:
                        monthStats.videos += 1
                    case .unknown:
                        break
                    }
                    monthStats.size += file.size
                    monthlyStats[monthStart] = monthStats
                }
            }
        }
        
        let participantFiles = Dictionary(grouping: mediaFiles) { $0.participant }
        for (participant, files) in participantFiles {
            let participantImages = files.filter { $0.type == .image }.count
            let participantGifs = files.filter { $0.type == .gif }.count
            let participantVideos = files.filter { $0.type == .video }.count
            let participantSize = files.reduce(0) { $0 + $1.size }
            
            let dates = files.compactMap { $0.creationDate }
            let uniqueDays = Set(dates.map { calendar.startOfDay(for: $0) })
            let averagePerDay = uniqueDays.isEmpty ? 0.0 : Double(files.count) / Double(uniqueDays.count)
            
            let participantFileTypes = Dictionary(grouping: files) { $0.fileExtension }
                .mapValues { $0.count }
            
            participantStats[participant] = ParticipantMediaStats(
                imageCount: participantImages,
                gifCount: participantGifs,
                videoCount: participantVideos,
                totalSize: participantSize,
                averageMediaPerDay: averagePerDay,
                mostActiveMediaDays: Array(uniqueDays).sorted { (date1: Date, date2: Date) -> Bool in
                    date1 < date2
                },
                fileTypes: participantFileTypes
            )
        }
        
        let dailyMediaStats = dailyStats.map { date, stats in
            DailyMediaStats(
                date: date,
                imageCount: stats.images,
                gifCount: stats.gifs,
                videoCount: stats.videos,
                totalSize: stats.size
            )
        }.sorted { (stat1: DailyMediaStats, stat2: DailyMediaStats) -> Bool in
            stat1.date < stat2.date
        }
        
        let monthlyMediaStats = monthlyStats.map { date, stats in
            let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
            return MonthlyMediaStats(
                month: date,
                imageCount: stats.images,
                gifCount: stats.gifs,
                videoCount: stats.videos,
                totalSize: stats.size,
                averagePerDay: Double(stats.images + stats.gifs + stats.videos) / Double(daysInMonth)
            )
        }.sorted { (stat1: MonthlyMediaStats, stat2: MonthlyMediaStats) -> Bool in
            stat1.month < stat2.month
        }
        
        return MediaStats(
            totalImages: totalImages,
            totalGifs: totalGifs,
            totalVideos: totalVideos,
            totalSize: totalSize,
            mediaByParticipant: participantStats,
            dailyMediaStats: dailyMediaStats,
            monthlyMediaStats: monthlyMediaStats,
            fileTypes: fileTypes,
            mediaFiles: mediaFiles,
            chatName: nil
        )
    }
} 
