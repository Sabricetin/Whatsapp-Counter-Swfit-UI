import SwiftUI

struct SavedAnalysesList: View {
    let analyses: [SavedAnalysis]
    let onSelect: (SavedAnalysis) -> Void
    let onDelete: (UUID) -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Geçmiş Analizler")
                .font(.headline)
            
            ForEach(analyses) { analysis in
                Button(action: { onSelect(analysis) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(analysis.fileName)
                                .font(.headline)
                            Text(dateFormatter.string(from: analysis.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        onDelete(analysis.id)
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                }
            }
        }
    }
} 