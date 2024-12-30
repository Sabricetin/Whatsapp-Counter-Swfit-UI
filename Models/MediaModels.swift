import Foundation

struct SavedMediaAnalysis: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let date: Date
    let mediaStats: MediaStats
}

struct MediaStats: Codable {
    var totalImages: Int
    var totalGifs: Int
    var totalVideos: Int
    var totalSize: Int64
    var mediaByParticipant: [String: ParticipantMediaStats]
    var dailyMediaStats: [DailyMediaStats]
    var monthlyMediaStats: [MonthlyMediaStats]
    var fileTypes: [String: Int]
    var mediaFiles: [MediaFile]
    var chatName: String?
}

struct ParticipantMediaStats: Codable {
    var imageCount: Int
    var gifCount: Int
    var videoCount: Int
    var totalSize: Int64
    var averageMediaPerDay: Double
    var mostActiveMediaDays: [Date]
    var fileTypes: [String: Int]
}

struct DailyMediaStats: Codable, Identifiable {
    let id = UUID()
    var date: Date
    var imageCount: Int
    var gifCount: Int
    var videoCount: Int
    var totalSize: Int64
}

struct MonthlyMediaStats: Codable, Identifiable {
    let id = UUID()
    var month: Date
    var imageCount: Int
    var gifCount: Int
    var videoCount: Int
    var totalSize: Int64
    var averagePerDay: Double
}

enum MediaType: String, Codable {
    case image
    case gif
    case video
    case unknown
    
    static func detect(from fileExtension: String) -> MediaType {
        let ext = fileExtension.lowercased()
        switch ext {
        case "jpg", "jpeg", "png", "heic", "webp":
            return .image
        case "gif":
            return .gif
        case "mp4", "mov", "avi", "mkv", "webm":
            return .video
        default:
            return .unknown
        }
    }
}

struct MediaFile: Identifiable, Codable {
    let id: UUID
    private let relativePath: String
    let type: MediaType
    let size: Int64
    let creationDate: Date?
    let participant: String
    
    var url: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mediaPath = documentsPath.appendingPathComponent("MediaAnalysis")
        return mediaPath.appendingPathComponent(relativePath)
    }
    
    var fileExtension: String {
        url.pathExtension.lowercased()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case relativePath
        case type
        case size
        case creationDate
        case participant
    }
    
    init(id: UUID = UUID(), url: URL, type: MediaType, size: Int64, creationDate: Date?, participant: String) {
        self.id = id
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MediaAnalysis")
        self.relativePath = url.lastPathComponent
        self.type = type
        self.size = size
        self.creationDate = creationDate
        self.participant = participant
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        relativePath = try container.decode(String.self, forKey: .relativePath)
        type = try container.decode(MediaType.self, forKey: .type)
        size = try container.decode(Int64.self, forKey: .size)
        creationDate = try container.decodeIfPresent(Date.self, forKey: .creationDate)
        participant = try container.decode(String.self, forKey: .participant)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(relativePath, forKey: .relativePath)
        try container.encode(type, forKey: .type)
        try container.encode(size, forKey: .size)
        try container.encodeIfPresent(creationDate, forKey: .creationDate)
        try container.encode(participant, forKey: .participant)
    }
} 