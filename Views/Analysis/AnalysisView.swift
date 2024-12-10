import SwiftUI
import Charts

struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if let analysis = viewModel.analysis {
                    analysisDetailView(analysis: analysis)
                } else if let mediaStats = viewModel.mediaStats {
                    mediaAnalysisDetailView(stats: mediaStats)
                } else {
                    SavedAnalysesList(
                        analyses: viewModel.savedAnalyses,
                        mediaAnalyses: viewModel.savedMediaAnalyses,
                        onSelect: { viewModel.selectAnalysis($0) },
                        onSelectMedia: { viewModel.selectMediaAnalysis($0) },
                        onDelete: { viewModel.deleteAnalysis(id: $0) },
                        onDeleteMedia: { viewModel.deleteMediaAnalysis(id: $0) }
                    )
                }
            }
            .navigationTitle(Constants.Navigation.analysisTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.analysis != nil || viewModel.mediaStats != nil {
                        Button(action: {
                            // Mevcut analizi kaydet
                            if let currentAnalysis = viewModel.analysis,
                               let savedAnalysis = viewModel.savedAnalyses.first(where: { $0.analysis.timeRange.start == currentAnalysis.timeRange.start }) {
                                viewModel.saveLastSelectedAnalysis(savedAnalysis)
                            }
                            
                            // Mevcut medya analizini kaydet
                            if let currentMediaStats = viewModel.mediaStats,
                               let savedMediaAnalysis = viewModel.savedMediaAnalyses.first(where: { $0.mediaStats.totalSize == currentMediaStats.totalSize }) {
                                viewModel.saveLastSelectedMediaAnalysis(savedMediaAnalysis)
                            }
                            
                            // Görünümü temizle
                            viewModel.clearCurrentAnalysis()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Geri")
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.analysis != nil || viewModel.mediaStats != nil {
                        Button(action: viewModel.shareAnalysis) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func analysisDetailView(analysis: AnalysisSummary) -> some View {
        ScrollView {
            VStack(spacing: 20) {
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
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func mediaAnalysisDetailView(stats: MediaStats) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Özet Kartı
                VStack(alignment: .leading, spacing: 10) {
                    Text("Medya Özeti")
                        .font(.headline)
                    
                    HStack {
                        StatView(title: "Fotoğraflar", value: "\(stats.totalImages)")
                        Spacer()
                        StatView(title: "GIF'ler", value: "\(stats.totalGifs)")
                        Spacer()
                        StatView(title: "Videolar", value: "\(stats.totalVideos)")
                    }
                    
                    HStack {
                        StatView(title: "Toplam Medya", value: "\(stats.totalImages + stats.totalGifs + stats.totalVideos)")
                        Spacer()
                        StatView(title: "Toplam Boyut", value: ByteCountFormatter.string(fromByteCount: stats.totalSize, countStyle: .file))
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                // 2. Katılımcılar Listesi
                if !stats.mediaByParticipant.isEmpty {
                    ParticipantsMediaList(participants: stats.mediaByParticipant)
                }
                
                // 3. Pasta Grafiği
                if #available(iOS 16.0, *) {
                    MediaPieChartView(mediaByParticipant: stats.mediaByParticipant)
                }
                
                // 4. Medya Türü Dağılımı
                MediaTypeDistributionView(stats: stats)
                
                // 5. Medya Galerisi
                MediaGalleryView(mediaFiles: stats.mediaFiles)
                
                // 6. Aktivite Grafiği
                if #available(iOS 16.0, *) {
                    MediaActivityChartView(
                        dailyStats: stats.dailyMediaStats,
                        monthlyStats: stats.monthlyMediaStats
                    )
                }
                
                // 7. Detaylar Listesi
                MediaDetailsList(stats: stats)
            }
            .padding()
        }
    }
    
    // Yeni eklenen yardımcı view'lar
    private struct ParticipantsMediaList: View {
        let participants: [String: ParticipantMediaStats]
        @State private var showingDetail = false
        
        var body: some View {
            Button(action: { showingDetail = true }) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Katılımcılar")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Toplam Katılımcı: \(participants.count)")
                                .font(.subheadline)
                            if let mostActive = participants.max(by: { $0.value.totalSize < $1.value.totalSize }) {
                                Text("En Aktif: \(mostActive.key)")
                                    .font(.subheadline)
                            }
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
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingDetail) {
                MediaParticipantsDetailView(participants: participants)
            }
        }
    }
    
    private struct MediaTypeDistributionView: View {
        let stats: MediaStats
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Medya Türü Dağılımı")
                    .font(.headline)
                
                ForEach(Array(stats.fileTypes.sorted { $0.value > $1.value }), id: \.key) { type, count in
                    HStack {
                        Text(type.uppercased())
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline)
                            .bold()
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
    
    private struct MediaDetailsList: View {
        let stats: MediaStats
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Detaylar")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                // En aktif gün
                if let mostActiveDay = stats.dailyMediaStats.max(by: { $0.totalSize < $1.totalSize }) {
                    DetailRow(
                        detail: AnalysisDetail(
                            title: "En Aktif Gün",
                            value: formattedDate(mostActiveDay.date)
                        )
                    )
                }
                
                // En büyük medya boyutu
                if let largestFile = stats.mediaFiles.max(by: { $0.size < $1.size }) {
                    DetailRow(
                        detail: AnalysisDetail(
                            title: "En Büyük Medya",
                            value: ByteCountFormatter.string(fromByteCount: largestFile.size, countStyle: .file)
                        )
                    )
                }
                
                // Ortalama medya boyutu
                if !stats.mediaFiles.isEmpty {
                    let avgSize = stats.totalSize / Int64(stats.mediaFiles.count)
                    DetailRow(
                        detail: AnalysisDetail(
                            title: "Ortalama Boyut",
                            value: ByteCountFormatter.string(fromByteCount: avgSize, countStyle: .file)
                        )
                    )
                }
                
                // En aktif katılımcı
                if let mostActive = stats.mediaByParticipant.max(by: { $0.value.totalSize < $1.value.totalSize }) {
                    DetailRow(
                        detail: AnalysisDetail(
                            title: "En Aktif Katılımcı",
                            value: "\(mostActive.key) (\(mostActive.value.imageCount + mostActive.value.gifCount + mostActive.value.videoCount) medya)"
                        )
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        
        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }
    
    @available(iOS 16.0, *)
    private struct MediaPieChartView: View {
        let mediaByParticipant: [String: ParticipantMediaStats]
        @State private var selectedParticipant: String?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Medya Dağılımı")
                    .font(.headline)
                
                Chart {
                    ForEach(Array(mediaByParticipant.keys.sorted()), id: \.self) { participant in
                        if let stats = mediaByParticipant[participant] {
                            let total = stats.imageCount + stats.gifCount + stats.videoCount
                            SectorMark(
                                angle: .value("Medya", total),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Katılımcı", participant))
                            .opacity(selectedParticipant == nil ? 1 : (selectedParticipant == participant ? 1 : 0.3))
                        }
                    }
                }
                .frame(height: 240)
                .chartLegend(position: .bottom, spacing: 20)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
    
    @available(iOS 16.0, *)
    private struct MediaActivityChartView: View {
        let dailyStats: [DailyMediaStats]
        let monthlyStats: [MonthlyMediaStats]
        @State private var selectedTimeFrame: TimeFrame = .daily
        
        enum TimeFrame {
            case daily, monthly
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Medya Aktivitesi")
                    .font(.headline)
                
                Picker("Zaman Aralığı", selection: $selectedTimeFrame) {
                    Text("Günlük").tag(TimeFrame.daily)
                    Text("Aylık").tag(TimeFrame.monthly)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if selectedTimeFrame == .daily {
                    Chart {
                        ForEach(dailyStats) { stat in
                            BarMark(
                                x: .value("Tarih", formattedDate(stat.date)),
                                y: .value("Medya", stat.imageCount + stat.gifCount + stat.videoCount)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    .frame(height: 200)
                } else {
                    Chart {
                        ForEach(monthlyStats) { stat in
                            BarMark(
                                x: .value("Ay", formattedMonth(stat.month)),
                                y: .value("Medya", stat.imageCount + stat.gifCount + stat.videoCount)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    .frame(height: 200)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        
        private func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
        
        private func formattedMonth(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }
    
    private struct MediaParticipantsDetailView: View {
        let participants: [String: ParticipantMediaStats]
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                List {
                    ForEach(Array(participants.keys.sorted()), id: \.self) { participant in
                        if let stats = participants[participant] {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(participant)
                                    .font(.headline)
                                
                                HStack {
                                    StatView(title: "Fotoğraf", value: "\(stats.imageCount)")
                                    Spacer()
                                    StatView(title: "GIF", value: "\(stats.gifCount)")
                                    Spacer()
                                    StatView(title: "Video", value: "\(stats.videoCount)")
                                }
                                
                                Text("Toplam Boyut: \(ByteCountFormatter.string(fromByteCount: stats.totalSize, countStyle: .file))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .navigationTitle("Katılımcı Detayları")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Kapat") {
                            dismiss()
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


