import Foundation

struct ParticipantMediaStats: Codable {
    let totalFiles: Int
    let totalSize: Int64
    let averagePerDay: Double
    let fileTypes: [String: Int]
    let imageCount: Int
    let videoCount: Int
    let gifCount: Int
}

struct DailyMediaStats: Codable, Identifiable {
    var id: String { date.description }
    let date: Date
    let imageCount: Int
    let gifCount: Int
    let videoCount: Int
    let totalSize: Int64
}

struct MonthlyMediaStats: Codable, Identifiable {
    var id: String { month.description }
    let month: Date
    let imageCount: Int
    let gifCount: Int
    let videoCount: Int
    let totalSize: Int64
    let averagePerDay: Double
}

struct MediaFile: Codable, Identifiable {
    let id: UUID
    let url: URL
    let type: MediaType
    let size: Int64
    let creationDate: Date
    let participant: String
}

enum MediaType: String, Codable {
    case image
    case video
    case gif
    case unknown
    
    static func detect(from extension: String) -> MediaType {
        switch `extension`.lowercased() {
        case "jpg", "jpeg", "png", "heic", "webp":
            return .image
        case "mp4", "mov":
            return .video
        case "gif":
            return .gif
        default:
            return .unknown
        }
    }
}

struct MediaStats: Codable {
    let totalFiles: Int
    let imageCount: Int
    let videoCount: Int
    let gifCount: Int
    let totalSize: Int64
    let imageSize: Int64
    let videoSize: Int64
    let gifSize: Int64
    let filesByDate: [String: Int]
    let filesByType: [String: Int]
    let largestFiles: [MediaFile]
    let chatName: String?
    let mediaByParticipant: [String: ParticipantMediaStats]
    let dailyMediaStats: [DailyMediaStats]
    let monthlyMediaStats: [MonthlyMediaStats]
    let mediaFiles: [MediaFile]
    
    var totalImages: Int { imageCount }
    var totalVideos: Int { videoCount }
    var totalGifs: Int { gifCount }
    var fileTypes: [String: Int] { filesByType }
} 