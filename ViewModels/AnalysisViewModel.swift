import Foundation
import Combine
import SwiftUI
import OSLog

// Directly use the types without imports since they are in the same target
class AnalysisViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var analysis: AnalysisSummary?
    @Published var mediaStats: MediaStats?
    @Published var chartData: [ChartViewModel] = []
    @Published var details: [AnalysisDetail] = []
    @Published var savedAnalyses: [SavedAnalysis] = []
    @Published var savedMediaAnalyses: [SavedMediaAnalysis] = []
    @Published var error: String?
    @Published var shouldNavigateToAnalysis = false
    
    private let analysisStorage = AnalysisStorage()
    private let mediaAnalyzer = MediaAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WhatsApp-Counter", category: "AnalysisViewModel")
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    init() {
        setupNotificationObserver()
        loadSavedAnalyses()
        
        // Başlangıçta tüm analizleri temizle ve liste görünümünü göster
        analysis = nil
        mediaStats = nil
        chartData = []
        details = []
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default
            .publisher(for: Constants.Notifications.newAnalysis)
            .compactMap { $0.object as? AnalysisSummary }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] analysis in
                guard let self = self else { return }
                self.updateAnalysis(analysis)
                
                // Kaydedilen analizleri hemen yükle
                self.loadSavedAnalyses()
                
                // Detay sayfasına yönlendir
                self.shouldNavigateToAnalysis = true
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: Constants.Notifications.newMediaAnalysis)
            .compactMap { $0.object as? MediaStats }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                guard let self = self else { return }
                // MediaStats'i güncelle
                self.mediaStats = stats
                
                // Kaydedilen analizleri hemen yükle
                self.loadSavedAnalyses()
                
                // Detay sayfasına yönlendir
                self.shouldNavigateToAnalysis = true
            }
            .store(in: &cancellables)
    }
    
    private func loadLatestMediaAnalysis() {
        mediaStats = analysisStorage.getLatestMediaAnalysis()
    }
    
    private func updateAnalysis(_ summary: AnalysisSummary) {
        self.analysis = summary
        self.generateChartData()
        self.generateDetails()
    }
    
    func saveAnalysis(_ analysis: AnalysisSummary, fileName: String) {
        do {
            try analysisStorage.saveAnalysis(analysis, fileName: fileName)
            loadSavedAnalyses() // Kaydedilen analizleri hemen yükle
        } catch {
            logger.error("Failed to save analysis: \(error.localizedDescription)")
            self.error = Constants.Error.storageError
        }
    }
    
    func saveMediaAnalysis(_ mediaStats: MediaStats, fileName: String) {
        do {
            try analysisStorage.saveMediaAnalysis(mediaStats, fileName: fileName)
            loadSavedAnalyses()
        } catch {
            logger.error("Failed to save media analysis: \(error.localizedDescription)")
            self.error = Constants.Error.storageError
        }
    }
    
    func deleteAnalysis(id: UUID) {
        Task {
            do {
                try await MainActor.run {
                    try analysisStorage.deleteAnalysis(id: id)
                    loadSavedAnalyses()
                    
                    // Eğer silinen analiz şu an görüntülenen analizse, görüntüyü temizle
                    if let currentAnalysis = analysis,
                       let savedAnalysis = savedAnalyses.first(where: { $0.id == id }),
                       savedAnalysis.analysis.timeRange.start == currentAnalysis.timeRange.start {
                        analysis = nil
                        chartData = []
                        details = []
                        analysisStorage.clearLastSelectedAnalysis()
                    }
                }
            } catch {
                await MainActor.run {
                    logger.error("Failed to delete analysis: \(error.localizedDescription)")
                    self.error = Constants.Error.storageError
                }
            }
        }
    }
    
    func deleteMediaAnalysis(id: UUID) {
        Task {
            do {
                try await MainActor.run {
                    // Analizi sil
                    try analysisStorage.deleteMediaAnalysis(id: id)
                    // Listeyi güncelle
                    loadSavedAnalyses()
                    // Görünümü temizle
                    mediaStats = nil
                }
            } catch {
                await MainActor.run {
                    logger.error("Failed to delete media analysis: \(error.localizedDescription)")
                    self.error = Constants.Error.storageError
                }
            }
        }
    }
    
    private func loadSavedAnalyses() {
        // Normal analizleri yükle
        if let data = UserDefaults.standard.data(forKey: "saved_analyses"),
           let analyses = try? JSONDecoder().decode([SavedAnalysis].self, from: data) {
            self.savedAnalyses = analyses
        }
        
        // Medya analizlerini yükle
        if let data = UserDefaults.standard.data(forKey: "saved_media_analyses"),
           let analyses = try? JSONDecoder().decode([SavedMediaAnalysis].self, from: data) {
            self.savedMediaAnalyses = analyses
        }
    }
    
    func selectAnalysis(_ savedAnalysis: SavedAnalysis) {
        self.analysis = savedAnalysis.analysis
        self.generateChartData()
        self.generateDetails()
        analysisStorage.saveLastSelectedAnalysis(savedAnalysis)
    }
    
    func selectMediaAnalysis(_ savedMediaAnalysis: SavedMediaAnalysis) {
        // MediaStats'i güncelle
        self.mediaStats = savedMediaAnalysis.mediaStats
        
        // Son seçilen analizi kaydet
        if let encoded = try? JSONEncoder().encode(savedMediaAnalysis) {
            UserDefaults.standard.set(encoded, forKey: "last_selected_media_analysis")
        }
        
        // Detay sayfasına yönlendir
        shouldNavigateToAnalysis = true
        
        // Kaydedilen analizleri yükle
        loadSavedAnalyses()
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
    
    private func loadLastSelectedAnalyses() {
        // Son seçilen sohbet analizini yükle
        if let lastAnalysis = analysisStorage.getLastSelectedAnalysis() {
            self.analysis = lastAnalysis.analysis
            self.generateChartData()
            self.generateDetails()
        }
        
        // Son seçilen medya analizini yükle
        if let lastMediaAnalysis = analysisStorage.getLastSelectedMediaAnalysis() {
            self.mediaStats = lastMediaAnalysis.mediaStats
        }
    }
    
    func saveLastSelectedAnalysis(_ savedAnalysis: SavedAnalysis) {
        analysisStorage.saveLastSelectedAnalysis(savedAnalysis)
    }
    
    func saveLastSelectedMediaAnalysis(_ savedMediaAnalysis: SavedMediaAnalysis) {
        analysisStorage.saveLastSelectedMediaAnalysis(savedMediaAnalysis)
    }
    
    func clearCurrentAnalysis() {
        // Görünümü temizle
        analysis = nil
        mediaStats = nil
        chartData = []
        details = []
        shouldNavigateToAnalysis = false // Anasayfada kal
    }
} 
