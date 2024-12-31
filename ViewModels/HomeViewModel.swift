import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers
import OSLog

class HomeViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var selectedFileType: FileType?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var shouldNavigateToAnalysis = false
    
    @Published var savedAnalyses: [SavedAnalysis] = []
    @Published var savedMediaAnalyses: [SavedMediaAnalysis] = []
    
    private let fileAnalyzer = FileAnalyzer()
    private let mediaAnalyzer = MediaAnalyzer()
    private let analysisStorage = AnalysisStorage()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WhatsApp-Counter", category: "HomeViewModel")
    
    enum FileType: CaseIterable {
        case txt
        case zip
        case mediaZip
        
        var allowedTypes: [UTType] {
            switch self {
            case .txt:
                return [.plainText]
            case .zip, .mediaZip:
                return [.zip]
            }
        }
        
        var description: String {
            switch self {
            case .txt:
                return "TXT Dosyası Analizi"
            case .zip:
                return "ZIP Dosyası Analizi"
            case .mediaZip:
                return "Medya Analizi (ZIP)"
            }
        }
        
        var icon: String {
            switch self {
            case .txt:
                return "doc.text.fill"
            case .zip:
                return "doc.zipper"
            case .mediaZip:
                return "photo.fill"
            }
        }
    }
    
    func analyzeFile(url: URL, type: FileType) {
        logger.info("Starting analysis for file: \(url.lastPathComponent)")
        isAnalyzing = true
        shouldNavigateToAnalysis = false
        
        Task {
            do {
                logger.info("Analyzing file...")
                
                defer {
                    if FileManager.default.fileExists(atPath: url.path) {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
                
                switch type {
                case .txt:
                    let analysis = try await fileAnalyzer.analyzeFile(at: url, allowMedia: false)
                    try await analysisStorage.saveAnalysis(analysis, fileName: url.lastPathComponent)
                    NotificationCenter.default.post(name: Constants.Notifications.newAnalysis, object: analysis)
                    
                case .zip:
                    let analysis = try await fileAnalyzer.analyzeFile(at: url, allowMedia: true)
                    try await analysisStorage.saveAnalysis(analysis, fileName: url.lastPathComponent)
                    NotificationCenter.default.post(name: Constants.Notifications.newAnalysis, object: analysis)
                    
                case .mediaZip:
                    let mediaStats = try await fileAnalyzer.analyzeMediaZip(at: url)
                    try await analysisStorage.saveMediaAnalysis(mediaStats, fileName: url.lastPathComponent)
                    NotificationCenter.default.post(name: Constants.Notifications.newMediaAnalysis, object: mediaStats)
                }
                
                await MainActor.run {
                    isAnalyzing = false
                    shouldNavigateToAnalysis = true
                }
                
            } catch let error as FileAnalyzerError {
                await MainActor.run {
                    logger.error("Analysis failed with FileAnalyzerError: \(error)")
                    errorMessage = error.localizedDescription
                    showError = true
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    logger.error("Analysis failed with unexpected error: \(error.localizedDescription)")
                    errorMessage = Constants.Error.unknownError
                    showError = true
                    isAnalyzing = false
                }
            }
        }
    }
} 
