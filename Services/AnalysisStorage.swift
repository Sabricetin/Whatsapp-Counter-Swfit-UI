import Foundation

class AnalysisStorage {
    private let defaults = UserDefaults.standard
    private let storageKey = "saved_analyses"
    
    func saveAnalysis(_ analysis: AnalysisSummary, fileName: String) {
        var savedAnalyses = getSavedAnalyses()
        let newAnalysis = SavedAnalysis(
            id: UUID(),
            fileName: fileName,
            date: Date(),
            analysis: analysis
        )
        savedAnalyses.append(newAnalysis)
        
        if let encoded = try? JSONEncoder().encode(savedAnalyses) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
    
    func getSavedAnalyses() -> [SavedAnalysis] {
        guard let data = defaults.data(forKey: storageKey),
              let analyses = try? JSONDecoder().decode([SavedAnalysis].self, from: data) else {
            return []
        }
        return analyses.sorted { $0.date > $1.date }
    }
    
    func deleteAnalysis(id: UUID) {
        var savedAnalyses = getSavedAnalyses()
        savedAnalyses.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(savedAnalyses) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
} 