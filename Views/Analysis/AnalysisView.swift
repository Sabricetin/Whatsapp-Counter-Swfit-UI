import SwiftUI
import Charts

struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if let analysis = viewModel.analysis {
                                SummaryCard(analysis: analysis)
                                if !analysis.participantStats.isEmpty {
                                    ParticipantsList(participants: analysis.participantStats)
                                }
                                ChartView(data: viewModel.chartData)
                                DetailsList(details: viewModel.details)
                            } else {
                                if viewModel.savedAnalyses.isEmpty {
                                    Text("Henüz analiz yapılmadı")
                                        .foregroundColor(.secondary)
                                } else {
                                    SavedAnalysesList(
                                        analyses: viewModel.savedAnalyses,
                                        onSelect: viewModel.selectAnalysis,
                                        onDelete: viewModel.deleteAnalysis
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(Constants.Navigation.analysisTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.analysis != nil {
                        Button(action: {
                            viewModel.analysis = nil
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Geri")
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.analysis != nil {
                        Button(action: viewModel.shareAnalysis) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
}

struct SummaryCard: View {
    let analysis: AnalysisSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Özet")
                .font(.headline)
            
            HStack {
                StatView(title: "Toplam Mesaj", value: "\(analysis.totalMessages)")
                Spacer()
                StatView(title: "Toplam Medya", value: "\(analysis.totalMedia)")
                Spacer()
                StatView(title: "Aktif Gün", value: "\(analysis.activeDays)")
                Spacer()
                StatView(title: "Toplam Katılımcı", value: "\(analysis.totalParticipants)")
                Spacer()
                StatView(title: "Aktif Katılımcı", value: "\(analysis.activeParticipants)")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ChartView: View {
    let data: [ChartData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mesaj Dağılımı")
                .font(.headline)
                .padding(.bottom, 5)
            
            if #available(iOS 16.0, *) {
                Chart(data) { item in
                    BarMark(
                        x: .value("Tarih", item.date),
                        y: .value("Mesaj", item.count)
                    )
                }
                .frame(height: 200)
            } else {
                Text("Grafik görüntüleme için iOS 16 veya üstü gereklidir")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct DetailsList: View {
    let details: [AnalysisDetail]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Detaylar")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(details) { detail in
                DetailRow(detail: detail)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct DetailRow: View {
    let detail: AnalysisDetail
    
    var body: some View {
        HStack {
            Text(detail.title)
            Spacer()
            Text(detail.value)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
}

struct ParticipantsList: View {
    let participants: [ParticipantStat]
    @State private var showingDetail = false
    
    private var totalMessages: Int {
        participants.reduce(0) { $0 + $1.messageCount }
    }
    
    private func generateColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow]
        return colors[index % colors.count]
    }
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Katılımcılar")
                    .font(.headline)
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Özet bilgiler
                HStack {
                    VStack(alignment: .leading) {
                        Text("Toplam Mesaj: \(totalMessages)")
                            .font(.subheadline)
                        Text("Katılımcı Sayısı: \(participants.count)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .sheet(isPresented: $showingDetail) {
            ParticipantsDetailView(participants: participants)
        }
    }
}

struct ParticipantsDetailView: View {
    let participants: [ParticipantStat]
    @Environment(\.dismiss) var dismiss
    
    private var totalMessages: Int {
        participants.reduce(0) { $0 + $1.messageCount }
    }
    
    private func generateColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow]
        return colors[index % colors.count]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Centered pie chart
                    ZStack {
                        PieChartView(
                            data: participants.enumerated().map { index, participant in
                                PieSliceData(
                                    value: Double(participant.messageCount),
                                    color: generateColor(for: index)
                                )
                            }
                        )
                        .frame(width: 250, height: 250)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                    
                    // Renk göstergesi ve yüzdeler
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(generateColor(for: index))
                                    .frame(width: 12, height: 12)
                                
                                Text(participant.name)
                                
                                Spacer()
                                
                                Text("\(participant.messageCount) mesaj")
                                    .foregroundColor(.secondary)
                                
                                Text(String(format: "%.1f%%",
                                    Double(participant.messageCount) / Double(totalMessages) * 100))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    
                    // Detaylı istatistikler
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detaylı İstatistikler")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(participant.name)
                                    .font(.headline)
                                
                                HStack {
                                    StatisticRow(title: "Mesaj", value: "\(participant.messageCount)")
                                    Spacer()
                                    StatisticRow(title: "Medya", value: "\(participant.mediaCount)")
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 1)
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Katılımcı Detayları")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
        }
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }
}

struct PieChartView: View {
    let data: [PieSliceData]
    @State private var selectedSlice: Int? = nil
    
    private var total: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private var angles: [Angle] {
        var angles: [Angle] = []
        var currentAngle: Double = 0
        
        for slice in data {
            let sliceAngle = 360 * (slice.value / total)
            angles.append(Angle(degrees: currentAngle))
            currentAngle += sliceAngle
        }
        return angles
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<data.count, id: \.self) { index in
                PieSlice(
                    startAngle: angles[index],
                    endAngle: index + 1 < angles.count ? angles[index + 1] : .degrees(360),
                    color: data[index].color
                )
                .scaleEffect(selectedSlice == index ? 1.05 : 1.0)
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedSlice = selectedSlice == index ? nil : index
                    }
                }
            }
        }
        .animation(.spring(), value: selectedSlice)
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 0, y: 0)
            path.move(to: center)
            path.addArc(
                center: center,
                radius: 100,
                startAngle: startAngle - .degrees(90),
                endAngle: endAngle - .degrees(90),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
    }
}

struct PieSliceData {
    let value: Double
    let color: Color
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct SavedAnalysesList: View {
    let analyses: [SavedAnalysis]
    let onSelect: (SavedAnalysis) -> Void
    let onDelete: (UUID) -> Void
    
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
                            Text(analysis.date.formatted())
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
