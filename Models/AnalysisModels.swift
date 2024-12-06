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
}

struct ParticipantStat: Codable, Identifiable {
    let id: UUID
    let name: String
    let messageCount: Int
    let mediaCount: Int
    
    var messagePercentage: Double {
        Double(messageCount) / Double(messageCount) * 100.0
    }
}

struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct AnalysisDetail: Identifiable {
    let id: UUID
    let title: String
    let value: String
} 