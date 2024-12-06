import Foundation
import Combine
import SwiftUI
import UniformTypeIdentifiers

class HomeViewModel: ObservableObject {
    @Published var isAnalyzing = false
    @Published var selectedFileType: FileType?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var shouldNavigateToAnalysis = false
    
    private let fileAnalyzer = FileAnalyzer()
    private let analysisStorage = AnalysisStorage()
    
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
        isAnalyzing = true
        
        Task {
            do {
                let analysis = try await fileAnalyzer.analyzeFile(at: url)
                await MainActor.run {
                    analysisStorage.saveAnalysis(analysis, fileName: url.lastPathComponent)
                    NotificationCenter.default.post(
                        name: Constants.Notifications.newAnalysis,
                        object: analysis
                    )
                    isAnalyzing = false
                    shouldNavigateToAnalysis = true
                }
            } catch FileAnalyzerError.fileReadError {
                await MainActor.run {
                    errorMessage = Constants.Error.fileReadError
                    showError = true
                    isAnalyzing = false
                }
            } catch FileAnalyzerError.unsupportedFileType {
                await MainActor.run {
                    errorMessage = Constants.Error.unsupportedFile
                    showError = true
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isAnalyzing = false
                }
            }
        }
    }
} 