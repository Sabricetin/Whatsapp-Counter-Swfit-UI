import Foundation

enum Constants {
    enum Navigation {
        static let homeTitle = "Ana Sayfa"
        static let analysisTitle = "Analizler"
        static let settingsTitle = "Ayarlar"
    }
    
    enum Error {
        static let fileReadError = "Dosya okunamadı. Lütfen dosyanın erişilebilir olduğundan emin olun."
        static let unsupportedFile = "Bu dosya formatı desteklenmiyor. Lütfen WhatsApp sohbet yedeği (.txt) veya medya yedeği (.zip) yükleyin."
        static let parseError = "Dosya ayrıştırılamadı. Lütfen geçerli bir WhatsApp sohbet yedeği olduğundan emin olun."
        static let noMediaFound = "Medya dosyası bulunamadı. Lütfen WhatsApp medya yedeğinin doğru formatta olduğundan emin olun."
        static let zipExtractionError = "ZIP dosyası açılamadı. Lütfen dosyaya erişim izni verdiğinizden ve dosyanın bozuk olmadığından emin olun."
        static let storageError = "Depolama hatası. Cihazınızda yeterli boş alan olduğundan emin olun."
        static let thumbnailError = "Küçük resim oluşturulamadı. Medya dosyası bozuk olabilir."
        static let mediaLoadError = "Medya dosyası yüklenemedi. Dosya silinmiş veya taşınmış olabilir."
        static let unknownError = "Bilinmeyen bir hata oluştu. Lütfen tekrar deneyin."
        static let containsMediaFiles = "Bu ZIP dosyası medya içeriyor. Lütfen 'Medya Analizi (ZIP)' seçeneğini kullanın."
        static let invalidFormat = "Geçersiz dosya formatı. Lütfen doğru formatta bir dosya seçin."
    }
    
    enum FileTypes {
        static let supportedExtensions = ["txt", "zip"]
    }
    
    enum Notifications {
        static let newAnalysis = Notification.Name("newAnalysis")
        static let newMediaAnalysis = Notification.Name("newMediaAnalysis")
    }
} 