import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    let progress: Double
    
    init(progress: Double = 0) {
        self.progress = progress
    }
    
    var body: some View {
        VStack {
            Image(systemName: "arrow.clockwise")
                .resizable()
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Text("Analiz Ediliyor...")
                .font(.headline)
                .padding(.top)
            
            if progress > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                    .padding(.top, 8)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
} 