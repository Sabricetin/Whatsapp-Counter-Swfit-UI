import Foundation

enum Constants {
    enum FileTypes {
        static let supportedExtensions = ["txt", "zip"]
    }
    
    enum Navigation {
        static let homeTitle = "WhatsApp Analyzer"
        static let analysisTitle = "Analiz"
        static let settingsTitle = "Ayarlar"
    }
    
    enum Notifications {
        static let newAnalysis = Notification.Name("NewAnalysisAvailable")
    }
    
    enum Error {
        static let defaultError = "Bir hata oluştu"
        static let fileReadError = "Dosya okunamadı"
        static let unsupportedFile = "Desteklenmeyen dosya formatı"
    }
} 