import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    
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
        }
        .onAppear {
            isAnimating = true
        }
    }
} 