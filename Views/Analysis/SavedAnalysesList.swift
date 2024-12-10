import SwiftUI

struct SavedAnalysesList: View {
    let analyses: [SavedAnalysis]
    let mediaAnalyses: [SavedMediaAnalysis]
    let onSelect: (SavedAnalysis) -> Void
    let onSelectMedia: (SavedMediaAnalysis) -> Void
    let onDelete: (UUID) -> Void
    let onDeleteMedia: (UUID) -> Void
    
    var body: some View {
        List {
            if !analyses.isEmpty {
                Section(header: Text("Sohbet Analizleri")) {
                    ForEach(analyses) { analysis in
                        Button(action: { onSelect(analysis) }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(analysis.fileName)
                                        .font(.headline)
                                    Text(formattedDate(analysis.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    onDelete(analysis.id)
                                }
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            if !mediaAnalyses.isEmpty {
                Section(header: Text("Medya Analizleri")) {
                    ForEach(mediaAnalyses) { analysis in
                        Button(action: { onSelectMedia(analysis) }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(analysis.fileName)
                                        .font(.headline)
                                    Text(formattedDate(analysis.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    onDeleteMedia(analysis.id)
                                }
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .overlay {
            if analyses.isEmpty && mediaAnalyses.isEmpty {
                Text("Henüz analiz yapılmamış")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
} 