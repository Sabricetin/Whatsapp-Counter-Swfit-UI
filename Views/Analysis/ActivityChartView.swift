import SwiftUI
import Charts

struct ActivityChartView: View {
    let dailyStats: [DailyStats]
    let hourlyStats: [HourlyStats]
    @State private var selectedTimeFrame: TimeFrame = .daily
    @State private var selectedDateRange: DateRange = .month
    
    enum TimeFrame {
        case daily, hourly
    }
    
    var filteredDailyStats: [DailyStats] {
        // Temel kontroller
        guard !dailyStats.isEmpty else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Güvenli bir şekilde tarihleri filtrele
        let sortedStats = dailyStats
            .filter { stat in
                guard let date = calendar.startOfDay(for: stat.date) as Date? else { return false }
                return date <= now && stat.messageCount >= 0
            }
            .sorted { $0.date < $1.date }
        
        guard !sortedStats.isEmpty else { return [] }
        
        // Son tarihi al
        guard let lastDate = sortedStats.last?.date else { return [] }
        
        // Seçilen aralığa göre filtrele
        switch selectedDateRange {
        case .all:
            // Son 90 günü göster
            if let startDate = calendar.date(byAdding: .day, value: -90, to: lastDate) {
                return sortedStats.filter { $0.date >= startDate }
            }
            return sortedStats
            
        case .week, .month, .threeMonths, .sixMonths:
            guard let days = selectedDateRange.days,
                  let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: lastDate)
            else {
                return Array(sortedStats.suffix(30)) // Varsayılan son 30 gün
            }
            return sortedStats.filter { $0.date >= startDate }
        }
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            VStack(spacing: 16) {
                HStack {
                    // Zaman aralığı seçici
                    Picker("", selection: $selectedTimeFrame) {
                        Text("Günlük").tag(TimeFrame.daily)
                        Text("Saatlik").tag(TimeFrame.hourly)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if selectedTimeFrame == .daily {
                        // Tarih aralığı seçici
                        Picker("", selection: $selectedDateRange) {
                            ForEach(DateRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // Seçilen zaman aralığına göre grafik
                if selectedTimeFrame == .daily {
                    SimpleDailyChart(stats: filteredDailyStats, selectedDateRange: selectedDateRange)
                } else {
                    SimpleHourlyChart(stats: hourlyStats)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        } else {
            Text("iOS 16 veya üstü gerekli")
                .foregroundColor(.secondary)
        }
    }
}

@available(iOS 16.0, *)
struct SimpleDailyChart: View {
    let stats: [DailyStats]
    let selectedDateRange: DateRange
    @State private var selectedStat: DailyStats?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    
    private func updateDateFormat() {
        switch selectedDateRange {
        case .week, .month:
            dateFormatter.dateFormat = "d MMM"
        case .threeMonths, .sixMonths, .all:
            dateFormatter.dateFormat = "MMM yyyy"
        }
    }
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        
        // Varsayılan aralık (son 30 gün)
        let defaultEndDate = now
        let defaultStartDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        
        guard !stats.isEmpty,
              let firstDate = stats.first?.date,
              let lastDate = stats.last?.date
        else {
            return defaultStartDate...defaultEndDate
        }
        
        // Tarih aralığını biraz genişlet
        let startDate = calendar.date(byAdding: .day, value: -1, to: firstDate) ?? firstDate
        let endDate = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
        
        // Geçerlilik kontrolü
        if startDate <= endDate {
            return startDate...endDate
        }
        
        return defaultStartDate...defaultEndDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Seçili gün bilgisi
            if let stat = selectedStat {
                HStack {
                    Text(dateFormatter.string(from: stat.date))
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(stat.messageCount) mesaj")
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            
            if stats.isEmpty {
                Text("Veri bulunamadı")
                    .foregroundColor(.secondary)
                    .frame(height: 180)
            } else {
                Chart {
                    ForEach(stats) { stat in
                        if stat.date <= Date() { // Gelecek tarihleri filtrele
                            BarMark(
                                x: .value("Tarih", stat.date),
                                y: .value("Mesaj", max(0, stat.messageCount)) // Negatif değerleri engelle
                            )
                            .foregroundStyle(Color.blue.opacity(0.8))
                            .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 180)
                .chartXScale(domain: dateRange)
                .chartXAxis {
                    let stride: Calendar.Component = {
                        switch selectedDateRange {
                        case .week:
                            return .day
                        case .month:
                            return stats.count > 30 ? .weekOfMonth : .day
                        case .threeMonths, .sixMonths:
                            return .month
                        case .all:
                            return .month
                        }
                    }()
                    
                    AxisMarks(values: .stride(by: stride)) { value in
                        if let date = value.as(Date.self),
                           date <= Date() {
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
                                    .font(.caption)
                                    .rotationEffect(.degrees(-45))
                            }
                            AxisTick()
                            AxisGridLine()
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(.gray.opacity(0.2))
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x
                                        if let date = proxy.value(atX: x) as Date?,
                                           date <= Date(), // Gelecek tarihleri filtrele
                                           let stat = stats.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
                                           stat.messageCount >= 0 { // Negatif değerleri filtrele
                                            selectedStat = stat
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedStat = nil
                                    }
                            )
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct SimpleHourlyChart: View {
    let stats: [HourlyStats]
    @State private var selectedHour: HourlyStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Seçili saat bilgisi
            if let stat = selectedHour {
                HStack {
                    Text("\(stat.hour):00")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(stat.messageCount) mesaj")
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
            
            // Basit çizgi grafik
            Chart {
                ForEach(stats) { stat in
                    LineMark(
                        x: .value("Saat", stat.hour),
                        y: .value("Mesaj", stat.messageCount)
                    )
                    .foregroundStyle(Color.blue.opacity(0.8))
                    .interpolationMethod(.catmullRom)
                }
                .symbol(Circle())
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: 6)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("\(hour):00")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.gray.opacity(0.2))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x
                                    if let hour = proxy.value(atX: x) as Int?,
                                       let stat = stats.first(where: { $0.hour == hour }) {
                                        selectedHour = stat
                                    }
                                }
                                .onEnded { _ in
                                    selectedHour = nil
                                }
                        )
                }
            }
        }
    }
} 