import Foundation

struct SavedAnalysis: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let date: Date
    let analysis: AnalysisSummary
}

struct SavedMediaAnalysis: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let date: Date
    let mediaStats: MediaStats
}

struct AnalysisSummary: Codable {
    let totalMessages: Int
    let totalWords: Int
    let timeRange: DateRange
    let participantStats: [ParticipantStat]
    let dailyStats: [DailyStats]
    let hourlyStats: [HourlyStats]
    let emojiStats: EmojiStats
    let wordStats: WordStats
    var chatName: String?
}

struct ParticipantStat: Identifiable, Codable {
    let id: UUID
    let name: String
    let messageCount: Int
    let wordCount: Int
    let emojiCount: Int
    let averageMessageLength: Double
    let mostUsedEmojis: [EmojiStat]
    let mostUsedWords: [WordStat]
}

struct DailyStats: Identifiable, Codable {
    let id: UUID
    let date: Date
    let messageCount: Int
}

struct HourlyStats: Identifiable, Codable {
    let id: UUID
    let hour: Int
    let messageCount: Int
}

struct DateRange: Codable {
    let start: Date
    let end: Date
}

struct EmojiStats: Codable {
    let totalCount: Int
    let topEmojis: [EmojiStat]
    let emojisByParticipant: [String: [EmojiStat]]
}

struct EmojiStat: Identifiable, Codable {
    let id: UUID
    let emoji: String
    let count: Int
    let percentage: Double
}

struct WordStats: Codable {
    let totalCount: Int
    let uniqueCount: Int
    let topWords: [WordStat]
    let wordsByParticipant: [String: [WordStat]]
}

struct WordStat: Identifiable, Codable {
    let id: UUID
    let word: String
    let count: Int
    let percentage: Double
}

struct AnalysisDetail: Identifiable {
    var id: UUID { UUID() }
    let title: String
    let value: String
}

struct ChartViewModel: Identifiable {
    let id: UUID
    let date: Date
    let messageCount: Int
} 