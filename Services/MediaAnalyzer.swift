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
    
    func analyzeDirectory(at url: URL) async throws -> MediaStats {
        let fileManager = FileManager.default
        
        var totalFiles = 0
        var totalSize: Int64 = 0
        var imageCount = 0
        var videoCount = 0
        var gifCount = 0
        var imageSize: Int64 = 0
        var videoSize: Int64 = 0
        var gifSize: Int64 = 0
        var filesByDate: [String: Int] = [:]
        var filesByType: [String: Int] = [:]
        var mediaFiles: [MediaFile] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.contentTypeKey, .fileSizeKey, .creationDateKey]
        ) {
            for case let fileURL as URL in enumerator {
                guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                      let fileSize = attributes[.size] as? Int64,
                      let creationDate = attributes[.creationDate] as? Date else {
                    continue
                }
                
                let fileExtension = fileURL.pathExtension.lowercased()
                let dateString = dateFormatter.string(from: creationDate)
                let mediaType = MediaType.detect(from: fileExtension)
                
                filesByType[fileExtension, default: 0] += 1
                filesByDate[dateString, default: 0] += 1
                
                let mediaFile = MediaFile(
                    id: UUID(),
                    url: fileURL,
                    type: mediaType,
                    size: fileSize,
                    creationDate: creationDate,
                    participant: "Unknown"
                )
                
                mediaFiles.append(mediaFile)
                totalFiles += 1
                totalSize += fileSize
                
                switch mediaType {
                case .image:
                    imageCount += 1
                    imageSize += fileSize
                case .video:
                    videoCount += 1
                    videoSize += fileSize
                case .gif:
                    gifCount += 1
                    gifSize += fileSize
                case .unknown:
                    break
                }
            }
        }
        
        let largestFiles = mediaFiles
            .sorted { $0.size > $1.size }
            .prefix(10)
            .map { $0 }
        
        let uniqueDays = Set(mediaFiles.map { dateFormatter.string(from: $0.creationDate) }).count
        let averagePerDay = uniqueDays > 0 ? Double(totalFiles) / Double(uniqueDays) : 0
        
        var fileTypes: [String: Int] = [:]
        for file in mediaFiles {
            let ext = file.url.pathExtension.lowercased()
            fileTypes[ext, default: 0] += 1
        }
        
        let participantStats = ParticipantMediaStats(
            totalFiles: totalFiles,
            totalSize: totalSize,
            averagePerDay: averagePerDay,
            fileTypes: fileTypes,
            imageCount: imageCount,
            videoCount: videoCount,
            gifCount: gifCount
        )
        
        return MediaStats(
            totalFiles: totalFiles,
            imageCount: imageCount,
            videoCount: videoCount,
            gifCount: gifCount,
            totalSize: totalSize,
            imageSize: imageSize,
            videoSize: videoSize,
            gifSize: gifSize,
            filesByDate: filesByDate,
            filesByType: filesByType,
            largestFiles: Array(largestFiles),
            chatName: "",
            mediaByParticipant: ["Unknown": participantStats],
            dailyMediaStats: [],
            monthlyMediaStats: [],
            mediaFiles: mediaFiles
        )
    }
}
