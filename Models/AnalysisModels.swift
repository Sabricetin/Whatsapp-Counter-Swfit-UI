import Foundation

// DateRange enum'ını burada tanımlayalım
public enum DateRange: String, Codable, CaseIterable {
    case week = "1 Hafta"
    case month = "1 Ay"
    case threeMonths = "3 Ay"
    case yearly = "Yıllık"
    case all = "Tümü"
    
    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .yearly: return 365
        case .all: return nil
        }
    }
    
    // Tarih aralığı hesaplama
    func getDateRange(from referenceDate: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: referenceDate)
        
        let start: Date
        switch self {
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        case .month:
            start = calendar.date(byAdding: .day, value: -30, to: end) ?? end
        case .threeMonths:
            start = calendar.date(byAdding: .day, value: -90, to: end) ?? end
        case .yearly:
            start = calendar.date(byAdding: .day, value: -365, to: end) ?? end
        case .all:
            start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
        }
        
        return (start, end)
    }
    
    // Başlangıç ve bitiş tarihleri için hesaplanmış özellikler
    var start: Date {
        getDateRange().start
    }
    
    var end: Date {
        getDateRange().end
    }
}

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
    let id: UUID
    let fileName: String
    let timeRange: DateRange
    let totalMessages: Int
    let participantCount: Int
    let hasMedia: Bool
    let createdAt: Date
    let totalWords: Int
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