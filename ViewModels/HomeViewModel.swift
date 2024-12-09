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
    
    private let fileAnalyzer = FileAnalyzer()
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
        
        Task {
            do {
                logger.info("Analyzing file...")
                let analysis = try await fileAnalyzer.analyzeFile(at: url)
                
                await MainActor.run {
                    logger.info("Analysis completed successfully")
                    analysisStorage.saveAnalysis(analysis, fileName: url.lastPathComponent)
                    NotificationCenter.default.post(
                        name: Constants.Notifications.newAnalysis,
                        object: analysis
                    )
                    isAnalyzing = false
                    shouldNavigateToAnalysis = true
                }
            } catch {
                await MainActor.run {
                    logger.error("Analysis failed: \(error.localizedDescription)")
                    switch error {
                    case FileAnalyzerError.fileReadError:
                        errorMessage = Constants.Error.fileReadError
                    case FileAnalyzerError.unsupportedFileType:
                        errorMessage = Constants.Error.unsupportedFile
                    case FileAnalyzerError.parseError:
                        errorMessage = Constants.Error.parseError
                    default:
                        errorMessage = error.localizedDescription
                    }
                    showError = true
                    isAnalyzing = false
                }
            }
        }
    }
} 
