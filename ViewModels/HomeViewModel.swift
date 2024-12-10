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
        
        Task {
            do {
                logger.info("Analyzing file...")
                
                switch type {
                case .txt, .zip:
                    let analysis = try await fileAnalyzer.analyzeFile(at: url, allowMedia: false)
                    await MainActor.run {
                        logger.info("Analysis completed successfully")
                        NotificationCenter.default.post(
                            name: Constants.Notifications.newAnalysis,
                            object: analysis
                        )
                        isAnalyzing = false
                        shouldNavigateToAnalysis = true
                    }
                    
                case .mediaZip:
                    let mediaStats = try await mediaAnalyzer.analyzeMediaZip(at: url)
                    await MainActor.run {
                        logger.info("Media analysis completed successfully")
                        do {
                            let fileName = url.deletingPathExtension().lastPathComponent
                            
                            try analysisStorage.saveMediaAnalysis(mediaStats, fileName: fileName)
                            
                            NotificationCenter.default.post(
                                name: Constants.Notifications.newMediaAnalysis,
                                object: mediaStats
                            )
                            
                            isAnalyzing = false
                            shouldNavigateToAnalysis = true
                        } catch {
                            logger.error("Failed to save media analysis: \(error.localizedDescription)")
                            errorMessage = Constants.Error.storageError
                            showError = true
                            isAnalyzing = false
                        }
                    }
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
                    case FileAnalyzerError.containsMediaFiles:
                        errorMessage = Constants.Error.containsMediaFiles
                    case MediaAnalyzerError.noMediaFound:
                        errorMessage = Constants.Error.noMediaFound
                    case MediaAnalyzerError.zipExtractionError:
                        errorMessage = Constants.Error.zipExtractionError
                    case AnalysisStorageError.encodingError, AnalysisStorageError.fileSystemError:
                        errorMessage = Constants.Error.storageError
                    default:
                        errorMessage = Constants.Error.unknownError
                    }
                    showError = true
                    isAnalyzing = false
                }
            }
        }
    }
} 
