import SwiftUI
import Charts

struct ActivityChartView: View {
    let dailyStats: [DailyStats]
    let hourlyStats: [HourlyStats]
    @State private var selectedTimeFrame: TimeFrame = .daily
    
    enum TimeFrame {
        case daily, hourly
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Zaman Aralığı", selection: $selectedTimeFrame) {
                    Text("Günlük").tag(TimeFrame.daily)
                    Text("Saatlik").tag(TimeFrame.hourly)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                if selectedTimeFrame == .daily {
                    DailyActivityChart(stats: dailyStats)
                } else {
                    HourlyActivityChart(stats: hourlyStats)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        } else {
            Text("Grafik görüntüleme için iOS 16 veya üstü gereklidir")
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

@available(iOS 16.0, *)
struct DailyActivityChart: View {
    let stats: [DailyStats]
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Günlük Aktivite")
                .font(.headline)
            
            Chart {
                ForEach(stats) { stat in
                    BarMark(
                        x: .value("Tarih", dateFormatter.string(from: stat.date)),
                        y: .value("Mesaj", stat.messageCount)
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
    }
}

@available(iOS 16.0, *)
struct HourlyActivityChart: View {
    let stats: [HourlyStats]
    
    private func formatHour(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saatlik Aktivite")
                .font(.headline)
            
            Chart {
                ForEach(stats) { stat in
                    LineMark(
                        x: .value("Saat", formatHour(stat.hour)),
                        y: .value("Mesaj", stat.messageCount)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    if let strValue = value.as(String.self) {
                        AxisValueLabel {
                            Text(strValue)
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
    }
} 