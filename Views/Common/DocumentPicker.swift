import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let onSelection: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelection: onSelection)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onSelection: (URL) -> Void
        
        init(onSelection: @escaping (URL) -> Void) {
            self.onSelection = onSelection
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Güvenli erişim için URL'yi kopyala
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            
            do {
                // Eğer varsa eski dosyayı sil
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                
                // Yeni dosyayı kopyala
                try FileManager.default.copyItem(at: url, to: tempURL)
                
                onSelection(tempURL)
            } catch {
                print("Error copying file: \(error)")
            }
        }
    }
}
