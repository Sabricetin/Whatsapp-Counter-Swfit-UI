import Foundation

struct SavedAnalysis: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let date: Date
    let analysis: AnalysisSummary
}

struct AnalysisSummary: Codable {
    let totalMessages: Int
    let totalMedia: Int
    let activeDays: Int
    let totalParticipants: Int
    let activeParticipants: Int
    let participantStats: [ParticipantStat]
    let dailyStats: [DailyStats]
    let hourlyStats: [HourlyStats]
}

struct ParticipantStat: Codable, Identifiable {
    let id: UUID
    let name: String
    let messageCount: Int
    let mediaCount: Int
    
    var messagePercentage: Double {
        guard totalMessages > 0 else { return 0 }
        return Double(messageCount) / Double(totalMessages) * 100
    }
    
    var totalMessages: Int {
        messageCount + mediaCount
    }
}

struct DailyStats: Codable, Identifiable {
    let id: UUID
    let date: String
    let messageCount: Int
    let mediaCount: Int
}

struct HourlyStats: Codable, Identifiable {
    let id: UUID
    let hour: Int
    let messageCount: Int
    let mediaCount: Int
}

struct AnalysisDetail: Identifiable {
    let id: UUID
    let title: String
    let value: String
}

struct ChartViewModel: Identifiable {
    let id = UUID()
    let date: String
    let messageCount: Int
    let mediaCount: Int
    
    init(from dailyStat: DailyStats) {
        self.date = dailyStat.date
        self.messageCount = dailyStat.messageCount
        self.mediaCount = dailyStat.mediaCount
    }
} 