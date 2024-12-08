import Foundation

enum Constants {
    enum Navigation {
        static let homeTitle = "Ana Sayfa"
        static let analysisTitle = "Analizler"
        static let settingsTitle = "Ayarlar"
    }
    
    enum Error {
        static let fileReadError = "Dosya okunamadı"
        static let unsupportedFile = "Desteklenmeyen dosya formatı"
        static let parseError = "Dosya ayrıştırılamadı"
    }
    
    enum FileTypes {
        static let supportedExtensions = ["txt", "zip"]
    }
    
    enum Notifications {
        static let newAnalysis = Notification.Name("newAnalysis")
    }
} 