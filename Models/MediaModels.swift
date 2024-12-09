import Foundation

struct MediaStats: Codable {
    let totalImages: Int
    let totalVideos: Int
    let totalSize: Int64 // Bayt cinsinden
    let mediaByParticipant: [String: ParticipantMediaStats]
    let dailyMediaStats: [DailyMediaStats]
    let monthlyMediaStats: [MonthlyMediaStats]
    let fileTypes: [String: Int] // Dosya uzantısı bazında sayım
    let mediaFiles: [MediaFile] // Medya dosyalarının kendisi
}

struct ParticipantMediaStats: Codable {
    let imageCount: Int
    let videoCount: Int
    let totalSize: Int64
    let averageMediaPerDay: Double
    let mostActiveMediaDays: [Date]
    let fileTypes: [String: Int]
}

struct DailyMediaStats: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let imageCount: Int
    let videoCount: Int
    let totalSize: Int64
}

struct MonthlyMediaStats: Codable, Identifiable {
    let id = UUID()
    let month: Date
    let imageCount: Int
    let videoCount: Int
    let totalSize: Int64
    let averagePerDay: Double
}

enum MediaType {
    case image
    case video
    case unknown
    
    static func detect(from fileExtension: String) -> MediaType {
        let ext = fileExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return .image
        case "mp4", "mov", "avi", "mkv", "webm":
            return .video
        default:
            return .unknown
        }
    }
}

struct MediaFile: Identifiable {
    let id = UUID()
    let url: URL
    let type: MediaType
    let size: Int64
    let creationDate: Date?
    let participant: String
    
    var fileExtension: String {
        url.pathExtension.lowercased()
    }
} 