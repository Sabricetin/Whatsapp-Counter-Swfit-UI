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
                                if #available(iOS 16.0, *) {
                                    PieChartView(participants: analysis.participantStats)
                                    WordEmojiAnalysisView(
                                        emojiStats: analysis.emojiStats,
                                        wordStats: analysis.wordStats
                                    )
                                    if let mediaStats = viewModel.mediaStats {
                                        MediaAnalysisView(stats: mediaStats)
                                    }
                                    ActivityChartView(
                                        dailyStats: analysis.dailyStats,
                                        hourlyStats: analysis.hourlyStats
                                    )
                                    MessageChart(data: viewModel.chartData)
                                }
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

@available(iOS 16.0, *)
struct MessageChart: View {
    let data: [ChartViewModel]
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mesaj Dağılımı")
                .font(.headline)
                .padding(.bottom, 5)
            
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Tarih", dateFormatter.string(from: item.date)),
                        y: .value("Mesaj", item.messageCount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    if let strValue = value.as(String.self) {
                        AxisValueLabel {
                            Text(strValue)
                                .rotationEffect(Angle(degrees: -45))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            
            HStack {
                Label("Mesajlar", systemImage: "message.fill")
                    .foregroundColor(.blue)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct SummaryCard: View {
    let analysis: AnalysisSummary
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Özet")
                .font(.headline)
            
            HStack {
                StatView(title: "Toplam Mesaj", value: "\(analysis.totalMessages)")
                Spacer()
                StatView(title: "Toplam Kelime", value: "\(analysis.totalWords)")
                Spacer()
                StatView(title: "Toplam Emoji", value: "\(analysis.emojiStats.totalCount)")
            }
            
            HStack {
                StatView(title: "Benzersiz Kelime", value: "\(analysis.wordStats.uniqueCount)")
                Spacer()
                StatView(title: "Katılımcı Sayısı", value: "\(analysis.participantStats.count)")
            }
            
            HStack {
                StatView(title: "Başlangıç", value: dateFormatter.string(from: analysis.timeRange.start))
                Spacer()
                StatView(title: "Bitiş", value: dateFormatter.string(from: analysis.timeRange.end))
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
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Katılımcılar")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Toplam Katılımcı: \(participants.count)")
                            .font(.subheadline)
                        Text("En Aktif: \(participants.first?.name ?? "")")
                            .font(.subheadline)
                    }
                    .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
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

//[... rest of the file remains unchanged ...]


