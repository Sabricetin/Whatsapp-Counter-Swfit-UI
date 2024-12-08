import Foundation
import Combine

class AnalysisViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var analysis: AnalysisSummary?
    @Published var chartData: [ChartViewModel] = []
    @Published var details: [AnalysisDetail] = []
    @Published var savedAnalyses: [SavedAnalysis] = []
    
    private let analysisStorage = AnalysisStorage()
    private var cancellables = Set<AnyCancellable>()
    
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
    }
    
    private func updateAnalysis(_ summary: AnalysisSummary) {
        self.analysis = summary
        self.generateChartData()
        self.generateDetails()
    }
    
    private func generateChartData() {
        guard let analysis = analysis else { return }
        self.chartData = analysis.dailyStats.map(ChartViewModel.init)
    }
    
    private func generateDetails() {
        guard let analysis = analysis else { return }
        
        // En aktif günü bul
        let mostActiveDay = analysis.dailyStats.max { $0.messageCount < $1.messageCount }
        
        // En aktif saati bul
        let mostActiveHour = analysis.hourlyStats.max { $0.messageCount < $1.messageCount }
        
        // Ortalama mesaj/gün hesapla
        let averageMessages = Double(analysis.totalMessages) / Double(analysis.activeDays)
        
        self.details = [
            AnalysisDetail(
                id: UUID(),
                title: "En Aktif Gün",
                value: mostActiveDay?.date ?? "Bilinmiyor"
            ),
            AnalysisDetail(
                id: UUID(),
                title: "En Aktif Saat",
                value: mostActiveHour.map { String(format: "%02d:00", $0.hour) } ?? "Bilinmiyor"
            ),
            AnalysisDetail(
                id: UUID(),
                title: "Ortalama Mesaj/Gün",
                value: String(format: "%.1f", averageMessages)
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