import Foundation
import Combine

class AnalysisViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var analysis: AnalysisSummary?
    @Published var chartData: [ChartData] = []
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
        // Diğer verileri güncelle
        self.generateChartData()
        self.generateDetails()
    }
    
    private func generateChartData() {
        // Chart verilerini oluştur
        self.chartData = [
            ChartData(date: Date(), count: 10),
            ChartData(date: Date().addingTimeInterval(86400), count: 20),
            ChartData(date: Date().addingTimeInterval(172800), count: 15)
        ]
    }
    
    private func generateDetails() {
        // Detayları oluştur
        self.details = [
            AnalysisDetail(id: UUID(), title: "En Aktif Gün", value: "Pazartesi"),
            AnalysisDetail(id: UUID(), title: "En Aktif Saat", value: "21:00"),
            AnalysisDetail(id: UUID(), title: "Ortalama Mesaj/Gün", value: "33")
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