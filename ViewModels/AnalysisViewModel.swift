import Foundation
import Combine
import SwiftUI

// Directly use the types without imports since they are in the same target
class AnalysisViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var analysis: AnalysisSummary?
    @Published var mediaStats: MediaStats?
    @Published var chartData: [ChartViewModel] = []
    @Published var details: [AnalysisDetail] = []
    @Published var savedAnalyses: [SavedAnalysis] = []
    
    private let analysisStorage = AnalysisStorage()
    private let mediaAnalyzer = MediaAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    init() {
        setupNotificationObserver()
        loadSavedAnalyses()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default
            .publisher(for: Constants.Notifications.newAnalysis)
            .compactMap { $0.object as? AnalysisSummary }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] analysis in
                self?.updateAnalysis(analysis)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: Constants.Notifications.newMediaAnalysis)
            .compactMap { $0.object as? MediaStats }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.mediaStats = stats
            }
            .store(in: &cancellables)
    }
    
    private func updateAnalysis(_ summary: AnalysisSummary) {
        self.analysis = summary
        self.generateChartData()
        self.generateDetails()
    }
    
    private func generateChartData() {
        guard let analysis = analysis else { return }
        self.chartData = analysis.dailyStats.map { dailyStat in
            ChartViewModel(
                id: dailyStat.id,
                date: dailyStat.date,
                messageCount: dailyStat.messageCount
            )
        }
    }
    
    private func generateDetails() {
        guard let analysis = analysis else { return }
        
        // En aktif günü bul
        let mostActiveDay = analysis.dailyStats.max { $0.messageCount < $1.messageCount }
        
        // En aktif saati bul
        let mostActiveHour = analysis.hourlyStats.max { $0.messageCount < $1.messageCount }
        
        // Aktif gün sayısını hesapla
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: analysis.timeRange.start, to: analysis.timeRange.end).day ?? 0
        let activeDays = max(1, daysBetween + 1)
        
        // Ortalama mesaj/gün hesapla
        let averageMessages = Double(analysis.totalMessages) / Double(activeDays)
        
        // En çok kullanılan emoji ve kelime
        let topEmoji = analysis.emojiStats.topEmojis.first
        let topWord = analysis.wordStats.topWords.first
        
        self.details = [
            AnalysisDetail(
                title: "En Aktif Gün",
                value: mostActiveDay.map { dateFormatter.string(from: $0.date) } ?? "Bilinmiyor"
            ),
            AnalysisDetail(
                title: "En Aktif Saat",
                value: mostActiveHour.map { String(format: "%02d:00", $0.hour) } ?? "Bilinmiyor"
            ),
            AnalysisDetail(
                title: "Ortalama Mesaj/Gün",
                value: String(format: "%.1f", averageMessages)
            ),
            AnalysisDetail(
                title: "En Çok Kullanılan Emoji",
                value: topEmoji.map { "\($0.emoji) (\($0.count)x)" } ?? "Yok"
            ),
            AnalysisDetail(
                title: "En Çok Kullanılan Kelime",
                value: topWord.map { "\($0.word) (\($0.count)x)" } ?? "Yok"
            )
        ]
    }
    
    func shareAnalysis() {
        // Paylaşım işlemleri buraya gelecek
    }
    
    private func loadSavedAnalyses() {
        savedAnalyses = analysisStorage.getSavedAnalyses()
    }
    
    func deleteAnalysis(id: UUID) {
        analysisStorage.deleteAnalysis(id: id)
        loadSavedAnalyses()
    }
    
    func selectAnalysis(_ savedAnalysis: SavedAnalysis) {
        self.analysis = savedAnalysis.analysis
        self.generateChartData()
        self.generateDetails()
    }
} 