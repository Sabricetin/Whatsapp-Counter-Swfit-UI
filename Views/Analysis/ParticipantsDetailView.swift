import SwiftUI

struct ParticipantsDetailView: View {
    let participants: [ParticipantStat]
    @Environment(\.dismiss) var dismiss
    
    private var totalMessages: Int {
        participants.reduce(0) { $0 + $1.messageCount }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if #available(iOS 16.0, *) {
                        PieChartView(participants: participants)
                            .frame(height: 300)
                            .padding(.top, 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(participants) { participant in
                            ParticipantRow(
                                participant: participant,
                                totalMessages: totalMessages
                            )
                        }
                    }
                    .padding()
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

struct ParticipantRow: View {
    let participant: ParticipantStat
    let totalMessages: Int
    
    private var percentage: Double {
        Double(participant.messageCount) / Double(totalMessages) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(participant.name)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Mesaj")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(participant.messageCount)")
                        .font(.subheadline)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Kelime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(participant.wordCount)")
                        .font(.subheadline)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Emoji")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(participant.emojiCount)")
                        .font(.subheadline)
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Yüzde")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", percentage))
                        .font(.subheadline)
                        .bold()
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
} 