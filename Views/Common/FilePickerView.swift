import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDocumentPicker = false
    @State private var selectedType: HomeViewModel.FileType?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(HomeViewModel.FileType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                        showDocumentPicker = true
                    }) {
                        Text(type.description)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Analiz Türü")
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
            .sheet(isPresented: $showDocumentPicker) {
                if let type = selectedType {
                    DocumentPicker(
                        types: type.allowedTypes,
                        onSelection: { url in
                            viewModel.analyzeFile(url: url, type: type)
                            dismiss()
                        }
                    )
                }
            }
        }
    }
} 