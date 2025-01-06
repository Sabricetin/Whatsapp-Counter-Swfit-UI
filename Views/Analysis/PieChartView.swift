import SwiftUI
import Charts

@available(iOS 16.0, *)
struct PieChartView: View {
    let participants: [ParticipantStat]
    @State private var selectedIndex: Int?
    @State private var scale: CGFloat = 0.01
    @State private var progress: Double = 0
    @State private var showLabels = false
    
    private var totalMessages: Int {
        participants.reduce(0) { $0 + $1.messageCount }
    }
    
    private func calculatePercentage(_ messageCount: Int) -> Double {
        guard totalMessages > 0 else { return 0 }
        return Double(messageCount) / Double(totalMessages) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mesaj Dağılımı")
                .font(.headline)
            
            let chartData = participants.enumerated().map { index, participant in
                ParticipantChartData(
                    id: participant.id,
                    index: index,
                    name: participant.name,
                    messageCount: Int(Double(participant.messageCount) * progress),
                    messagePercentage: calculatePercentage(participant.messageCount)
                )
            }.sorted { $0.messageCount > $1.messageCount }
            
            Chart(chartData) { participant in
                SectorMark(
                    angle: .value(
                        "Mesaj",
                        max(1, participant.messageCount)
                    ),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Katılımcı", participant.name))
                .opacity(selectedIndex == nil ? 1 : (selectedIndex == participant.index ? 1 : 0.3))
                .annotation(position: .overlay) {
                    Text("\(Int(participant.messagePercentage))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        .opacity(showLabels ? 1 : 0)
                }
            }
            .frame(height: 240)
            .chartLegend(position: .bottom, spacing: 20) {
                FlowLayout(alignment: .leading, spacing: 8) {
                    ForEach(participants) { participant in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue) // Chart color will match automatically
                                .frame(width: 8, height: 8)
                            Text(participant.name)
                                .font(.caption)
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
            }
            .chartAngleSelection(value: $selectedIndex)
            .scaleEffect(scale)
            
            if let selectedIndex,
               selectedIndex < participants.count {
                let participant = participants[selectedIndex]
                HStack {
                    Text(participant.name)
                        .font(.headline)
                    Spacer()
                    Text("\(participant.messageCount) mesaj")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                .opacity(progress)
                
                Text("Toplam mesajların %\(String(format: "%.1f", calculatePercentage(participant.messageCount)))'i")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(progress)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1
            }
            
            withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
                progress = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showLabels = true
                }
            }
        }
    }
}

private struct ParticipantChartData: Identifiable {
    let id: UUID
    let index: Int
    let name: String
    let messageCount: Int
    let messagePercentage: Double
}
