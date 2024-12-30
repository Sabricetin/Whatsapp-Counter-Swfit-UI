import SwiftUI
import Charts

struct MediaAnalysisView: View {
    let stats: MediaStats
    @State private var selectedTab = 0
    
    private var totalMediaCount: Int {
        stats.totalImages + stats.totalVideos
    }
    
    private var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: stats.totalSize, countStyle: .file)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Özet Kartı
            VStack(alignment: .leading, spacing: 12) {
                Text("Medya Özeti")
                    .font(.headline)
                
                HStack {
                    MediaStatView(title: "Toplam Medya", value: "\(totalMediaCount)")
                    Spacer()
                    MediaStatView(title: "Resimler", value: "\(stats.totalImages)")
                    Spacer()
                    MediaStatView(title: "Videolar", value: "\(stats.totalVideos)")
                }
                
                HStack {
                    MediaStatView(title: "Toplam Boyut", value: formattedTotalSize)
                    Spacer()
                    MediaStatView(title: "Dosya Tipleri", value: "\(stats.fileTypes.count)")
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
            
            // Sekmeli Görünüm
            Picker("Analiz Tipi", selection: $selectedTab) {
                Text("Galeri").tag(0)
                Text("Zaman").tag(1)
                Text("Katılımcılar").tag(2)
                Text("Dosya Tipleri").tag(3)
                Text("Detaylar").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Seçili Sekme İçeriği
            Group {
                switch selectedTab {
                case 0:
                    if stats.mediaFiles.isEmpty {
                        Text("Medya dosyası bulunamadı")
                            .foregroundColor(.secondary)
                    } else {
                        MediaGalleryView(mediaFiles: stats.mediaFiles)
                    }
                case 1:
                    if #available(iOS 16.0, *) {
                        TimeBasedMediaView(stats: stats)
                    }
                case 2:
                    ParticipantMediaView(stats: stats)
                case 3:
                    FileTypeMediaView(stats: stats)
                case 4:
                    DetailedAnalysisView(stats: stats)
                default:
                    EmptyView()
                }
            }
        }
        .padding()
    }
}

// Yeni eklenen view - Detaylı Analiz Görünümü
struct DetailedAnalysisView: View {
    let stats: MediaStats
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Katılımcı İstatistikleri
                if !stats.mediaByParticipant.isEmpty {
                    ParticipantStatsView(participants: stats.mediaByParticipant)
                }
                
                // Pasta Grafiği
                if #available(iOS 16.0, *) {
                    MediaPieChartView(mediaByParticipant: stats.mediaByParticipant)
                }
                
                // Aktivite Grafiği
                if #available(iOS 16.0, *) {
                    MediaActivityChartView(
                        dailyStats: stats.dailyMediaStats,
                        monthlyStats: stats.monthlyMediaStats
                    )
                }
                
                // Detaylar Listesi
                MediaDetailsList(stats: stats)
            }
        }
    }
}

// Yeni eklenen view - Katılımcı İstatistikleri
struct ParticipantStatsView: View {
    let participants: [String: ParticipantMediaStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Katılımcı İstatistikleri")
                .font(.headline)
            
            ForEach(Array(participants.keys.sorted()), id: \.self) { participant in
                if let stats = participants[participant] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(participant)
                            .font(.subheadline)
                            .bold()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Resim: \(stats.imageCount)")
                                Text("Video: \(stats.videoCount)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Toplam: \(stats.imageCount + stats.videoCount)")
                                Text("Boyut: \(ByteCountFormatter.string(fromByteCount: stats.totalSize, countStyle: .file))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// Yeni eklenen view - Medya Pasta Grafiği
@available(iOS 16.0, *)
struct MediaPieChartView: View {
    let mediaByParticipant: [String: ParticipantMediaStats]
    @State private var selectedParticipant: String?
    
    private var totalMedia: Int {
        mediaByParticipant.values.reduce(0) { $0 + $1.imageCount + $1.videoCount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Medya Dağılımı")
                .font(.headline)
            
            Chart {
                ForEach(Array(mediaByParticipant.keys.sorted()), id: \.self) { participant in
                    if let stats = mediaByParticipant[participant] {
                        let total = stats.imageCount + stats.videoCount
                        let percentage = Double(total) / Double(totalMedia) * 100
                        
                        SectorMark(
                            angle: .value("Medya", total),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Katılımcı", participant))
                        .opacity(selectedParticipant == nil ? 1 : (selectedParticipant == participant ? 1 : 0.3))
                        .annotation(position: .overlay) {
                            Text("\(Int(percentage))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                    }
                }
            }
            .frame(height: 240)
            .chartLegend(position: .bottom, spacing: 20)
            
            if let selectedParticipant,
               let stats = mediaByParticipant[selectedParticipant] {
                let total = stats.imageCount + stats.videoCount
                let percentage = Double(total) / Double(totalMedia) * 100
                
                HStack {
                    Text(selectedParticipant)
                        .font(.headline)
                    Spacer()
                    Text("\(total) medya")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                Text("Toplam medyanın %\(String(format: "%.1f", percentage))'i")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct MediaStatView: View {
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

@available(iOS 16.0, *)
struct TimeBasedMediaView: View {
    let stats: MediaStats
    @State private var timeFrame: TimeFrame = .daily
    
    enum TimeFrame {
        case daily, monthly
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Zaman Aralığı", selection: $timeFrame) {
                Text("Günlük").tag(TimeFrame.daily)
                Text("Aylık").tag(TimeFrame.monthly)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if timeFrame == .daily {
                DailyMediaChart(stats: stats.dailyMediaStats)
            } else {
                MonthlyMediaChart(stats: stats.monthlyMediaStats)
            }
        }
    }
}

@available(iOS 16.0, *)
struct DailyMediaChart: View {
    let stats: [DailyMediaStats]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        Chart {
            ForEach(stats) { stat in
                BarMark(
                    x: .value("Tarih", dateFormatter.string(from: stat.date)),
                    y: .value("Resim", stat.imageCount)
                )
                .foregroundStyle(Color.blue.gradient)
                
                BarMark(
                    x: .value("Tarih", dateFormatter.string(from: stat.date)),
                    y: .value("Video", stat.videoCount)
                )
                .foregroundStyle(Color.orange.gradient)
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
            Label("Resimler", systemImage: "photo")
                .foregroundColor(.blue)
            Label("Videolar", systemImage: "video")
                .foregroundColor(.orange)
        }
        .font(.caption)
    }
}

@available(iOS 16.0, *)
struct MonthlyMediaChart: View {
    let stats: [MonthlyMediaStats]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        Chart {
            ForEach(stats) { stat in
                BarMark(
                    x: .value("Ay", dateFormatter.string(from: stat.month)),
                    y: .value("Resim", stat.imageCount)
                )
                .foregroundStyle(Color.blue.gradient)
                
                BarMark(
                    x: .value("Ay", dateFormatter.string(from: stat.month)),
                    y: .value("Video", stat.videoCount)
                )
                .foregroundStyle(Color.orange.gradient)
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
            Label("Resimler", systemImage: "photo")
                .foregroundColor(.blue)
            Label("Videolar", systemImage: "video")
                .foregroundColor(.orange)
        }
        .font(.caption)
    }
}

struct ParticipantMediaView: View {
    let stats: MediaStats
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(stats.mediaByParticipant.keys.sorted()), id: \.self) { participant in
                    if let participantStats = stats.mediaByParticipant[participant] {
                        ParticipantMediaCard(
                            participant: participant,
                            stats: participantStats
                        )
                    }
                }
            }
        }
    }
}

struct ParticipantMediaCard: View {
    let participant: String
    let stats: ParticipantMediaStats
    
    private var totalMedia: Int {
        stats.imageCount + stats.videoCount
    }
    
    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: stats.totalSize, countStyle: .file)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(participant)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Toplam")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalMedia)")
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Resim")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.imageCount)")
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Video")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(stats.videoCount)")
                        .font(.title3)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Boyut")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedSize)
                        .font(.subheadline)
                        .bold()
                }
            }
            
            if !stats.fileTypes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(stats.fileTypes.keys.sorted()), id: \.self) { type in
                            if let count = stats.fileTypes[type] {
                                HStack {
                                    Text(".\(type)")
                                    Text("\(count)x")
                                        .foregroundColor(.secondary)
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

private struct FileTypeItem: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
}

struct FileTypeMediaView: View {
    let stats: MediaStats
    
    private var sortedFileTypes: [FileTypeItem] {
        stats.fileTypes.map { FileTypeItem(type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dosya Tipleri")
                    .font(.headline)
                
                ForEach(sortedFileTypes) { item in
                    HStack {
                        Text(".\(item.type)")
                            .font(.body)
                        
                        Spacer()
                        
                        Text("\(item.count) dosya")
                            .foregroundColor(.secondary)
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
}

@available(iOS 16.0, *)
struct MediaActivityChartView: View {
    let dailyStats: [DailyMediaStats]
    let monthlyStats: [MonthlyMediaStats]
    @State private var timeFrame: TimeFrame = .daily
    
    enum TimeFrame {
        case daily, monthly
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medya Aktivitesi")
                .font(.headline)
            
            Picker("Zaman Aralığı", selection: $timeFrame) {
                Text("Günlük").tag(TimeFrame.daily)
                Text("Aylık").tag(TimeFrame.monthly)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if timeFrame == .daily {
                DailyMediaActivityChart(stats: dailyStats)
            } else {
                MonthlyMediaActivityChart(stats: monthlyStats)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

@available(iOS 16.0, *)
private struct DailyMediaActivityChart: View {
    let stats: [DailyMediaStats]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        Chart {
            ForEach(stats) { stat in
                BarMark(
                    x: .value("Tarih", dateFormatter.string(from: stat.date)),
                    y: .value("Medya", stat.imageCount + stat.videoCount)
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
    }
}

@available(iOS 16.0, *)
private struct MonthlyMediaActivityChart: View {
    let stats: [MonthlyMediaStats]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        Chart {
            ForEach(stats) { stat in
                BarMark(
                    x: .value("Ay", dateFormatter.string(from: stat.month)),
                    y: .value("Medya", stat.imageCount + stat.videoCount)
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
    }
}

struct MediaDetailsList: View {
    let stats: MediaStats
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detaylar")
                .font(.headline)
            
            // En aktif gün
            if let mostActiveDay = stats.dailyMediaStats.max(by: { $0.totalSize < $1.totalSize }) {
                MediaDetailRow(title: "En Aktif Gün", value: dateFormatter.string(from: mostActiveDay.date))
            }
            
            // En büyük medya dosyası
            if let largestFile = stats.mediaFiles.max(by: { $0.size < $1.size }) {
                MediaDetailRow(
                    title: "En Büyük Medya",
                    value: "\(ByteCountFormatter.string(fromByteCount: largestFile.size, countStyle: .file))"
                )
            }
            
            // En aktif katılımcı
            if let mostActiveParticipant = stats.mediaByParticipant.max(by: { $0.value.totalSize < $1.value.totalSize }) {
                MediaDetailRow(title: "En Aktif Katılımcı", value: mostActiveParticipant.key)
            }
            
            // Ortalama günlük medya
            if !stats.dailyMediaStats.isEmpty {
                let avgMedia = Double(stats.mediaFiles.count) / Double(stats.dailyMediaStats.count)
                MediaDetailRow(
                    title: "Günlük Ortalama",
                    value: String(format: "%.1f medya", avgMedia)
                )
            }
            
            // Ortalama dosya boyutu
            if !stats.mediaFiles.isEmpty {
                let avgSize = Double(stats.totalSize) / Double(stats.mediaFiles.count)
                MediaDetailRow(
                    title: "Ortalama Boyut",
                    value: ByteCountFormatter.string(fromByteCount: Int64(avgSize), countStyle: .file)
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

private struct MediaDetailRow: View {
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