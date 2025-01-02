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
        guard let lastDate = sortedStats.last?.date else { return [] }
        
        // Seçilen aralığa göre filtrele ve grupla
        switch selectedDateRange {
        case .week, .month:
            // Günlük veriler
            guard let days = selectedDateRange.days,
                  let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: lastDate)
            else { return Array(sortedStats.suffix(30)) }
            return sortedStats.filter { $0.date >= startDate }
            
        case .threeMonths:
            // Haftalık grupla
            guard let startDate = calendar.date(byAdding: .day, value: -90, to: lastDate) else { return [] }
            let filteredStats = sortedStats.filter { $0.date >= startDate }
            return groupStatsByWeek(stats: filteredStats, calendar: calendar)
            
        case .yearly:
            // Aylık grupla
            guard let startDate = calendar.date(byAdding: .year, value: -1, to: lastDate) else { return [] }
            let filteredStats = sortedStats.filter { $0.date >= startDate }
            return groupStatsByMonth(stats: filteredStats, calendar: calendar)
            
        case .all:
            // Yıllık grupla
            return groupStatsByYear(stats: sortedStats, calendar: calendar)
        }
    }
    
    // Haftalık gruplama fonksiyonu
    private func groupStatsByWeek(stats: [DailyStats], calendar: Calendar) -> [DailyStats] {
        var weeklyStats: [Date: Int] = [:]
        
        for stat in stats {
            // Güvenli bir şekilde hafta başlangıcını hesapla
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: stat.date)
            if let weekStart = calendar.date(from: components) {
                weeklyStats[weekStart, default: 0] += stat.messageCount
            }
        }
        
        return weeklyStats.map { date, count in
            DailyStats(id: UUID(), date: date, messageCount: count)
        }.sorted { $0.date < $1.date }
    }
    
    // Aylık gruplama fonksiyonu
    private func groupStatsByMonth(stats: [DailyStats], calendar: Calendar) -> [DailyStats] {
        var monthlyStats: [Date: Int] = [:]
        
        for stat in stats {
            let components = calendar.dateComponents([.year, .month], from: stat.date)
            if let monthStart = calendar.date(from: components) {
                monthlyStats[monthStart, default: 0] += stat.messageCount
            }
        }
        
        return monthlyStats.map { date, count in
            DailyStats(id: UUID(), date: date, messageCount: count)
        }.sorted { $0.date < $1.date }
    }
    
    // Yıllık gruplama fonksiyonu
    private func groupStatsByYear(stats: [DailyStats], calendar: Calendar) -> [DailyStats] {
        var yearlyStats: [Date: Int] = [:]
        
        for stat in stats {
            let components = calendar.dateComponents([.year], from: stat.date)
            if let yearStart = calendar.date(from: components) {
                yearlyStats[yearStart, default: 0] += stat.messageCount
            }
        }
        
        return yearlyStats.map { date, count in
            DailyStats(id: UUID(), date: date, messageCount: count)
        }.sorted { $0.date < $1.date }
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
    
    // Tarih aralığı hesaplama için computed property
    private var dateRange: ClosedRange<Date> {
        guard let minDate = stats.first?.date,
              let maxDate = stats.last?.date else {
            let now = Date()
            return now...now
        }
        return minDate...maxDate
    }
    
    // Tarih formatını seçme
    private func getDateFormat() -> String {
        switch selectedDateRange {
        case .week, .month:
            return "d MMM"
        case .threeMonths:
            return "d MMM"
        case .yearly, .all:
            return "MMM yyyy"
        }
    }
    
    // X ekseni için stride hesaplama
    private func getAxisStride() -> Calendar.Component {
        switch selectedDateRange {
        case .week, .month:
            return .day
        case .threeMonths:
            return .weekOfYear
        case .yearly, .all:
            return .month
        }
    }
    
    private func formatDateRange(for date: Date) -> String {
        let calendar = Calendar.current
        
        switch selectedDateRange {
        case .threeMonths:
            // Haftanın başlangıç ve bitiş tarihlerini hesapla
            let weekStart = date // Bu zaten haftanın başlangıcı (groupStatsByWeek'ten geliyor)
            guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                return dateFormatter.string(from: date)
            }
            
            // Başlangıç ve bitiş için ayrı formatlayıcılar
            let startFormatter = DateFormatter()
            let endFormatter = DateFormatter()
            startFormatter.locale = Locale(identifier: "tr_TR")
            endFormatter.locale = Locale(identifier: "tr_TR")
            
            // Eğer başlangıç ve bitiş tarihleri farklı aylardaysa
            let startMonth = calendar.component(.month, from: weekStart)
            let endMonth = calendar.component(.month, from: weekEnd)
            
            if startMonth != endMonth {
                startFormatter.dateFormat = "d MMM"
                endFormatter.dateFormat = "d MMM"
            } else {
                startFormatter.dateFormat = "d"
                endFormatter.dateFormat = "d MMM"
            }
            
            let startStr = startFormatter.string(from: weekStart)
            let endStr = endFormatter.string(from: weekEnd)
            
            return "\(startStr) - \(endStr)"
            
        case .yearly, .all:
            dateFormatter.dateFormat = "MMM yyyy"
            return dateFormatter.string(from: date)
            
        default:
            dateFormatter.dateFormat = "d MMM"
            return dateFormatter.string(from: date)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Seçili stat gösterimi güncellendi
            if let stat = selectedStat {
                HStack {
                    Text(formatDateRange(for: stat.date))
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
                let maxValue = stats.map { $0.messageCount }.max() ?? 0
                
                Chart {
                    ForEach(stats) { stat in
                        if stat.date <= Date() {
                            BarMark(
                                x: .value("Tarih", stat.date),
                                y: .value("Mesaj", max(0, stat.messageCount)),
                                width: MarkDimension(floatLiteral: calculateBarWidth())
                            )
                            .foregroundStyle(Color.blue.opacity(0.8))
                            .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 180)
                .chartXScale(domain: dateRange)
                .chartYScale(domain: 0...(maxValue + 5))
                .chartXAxis {
                    let stride = getAxisStride()
                    
                    AxisMarks(values: .stride(by: stride)) { value in
                        AxisGridLine().foregroundStyle(.gray.opacity(0.2))
                        AxisTick().foregroundStyle(.gray.opacity(0.2))
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(.gray.opacity(0.2))
                        AxisTick()
                        if let val = value.as(Int.self) {
                            AxisValueLabel {
                                Text("\(val)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
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
                                        let xPosition = value.location.x
                                        if let date = proxy.value(atX: xPosition, as: Date.self) {
                                            handleChartTouch(at: date, proxy: proxy)
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
    
    private func handleChartTouch(at date: Date, proxy: ChartProxy) {
        guard date <= Date() else { return }
        
        let calendar = Calendar.current
        selectedStat = stats.first { stat in
            calendar.isDate(stat.date, inSameDayAs: date)
        }
    }
    
    // Bar genişliğini hesaplama fonksiyonu
    private func calculateBarWidth() -> CGFloat {
        switch selectedDateRange {
        case .week, .month:
            return 6 // Günlük görünüm için ince
        case .threeMonths:
            return 12 // Haftalık görünüm için orta
        case .yearly, .all:
            return 15 // Aylık ve yıllık görünüm için geniş
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
