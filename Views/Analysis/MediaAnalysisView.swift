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
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Seçili Sekme İçeriği
            Group {
                switch selectedTab {
                case 0:
                    MediaGalleryView(mediaFiles: stats.mediaFiles)
                case 1:
                    TimeBasedMediaView(stats: stats)
                case 2:
                    ParticipantMediaView(stats: stats)
                case 3:
                    FileTypeMediaView(stats: stats)
                default:
                    EmptyView()
                }
            }
        }
        .padding()
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