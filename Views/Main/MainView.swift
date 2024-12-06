import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var showAnalysisOptions = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Ana Sayfa", systemImage: "house.fill")
                    }
                    .tag(0)
                
                AnalysisView()
                    .tabItem {
                        Label("Analizler", systemImage: "chart.bar.fill")
                    }
                    .tag(1)
                
                SettingsView()
                    .tabItem {
                        Label("Ayarlar", systemImage: "gear")
                    }
                    .tag(2)
            }
            .overlay(
                Group {
                    if showAnalysisOptions {
                        Color.black
                            .opacity(0.2)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showAnalysisOptions = false
                                }
                            }
                    }
                }
            )
            
            // Analiz butonu ve options - sadece analiz yokken göster
            if !homeViewModel.isAnalyzing && selectedTab == 0 {
                VStack(spacing: 0) {
                    if showAnalysisOptions {
                        AnalysisOptionsView(viewModel: homeViewModel, isShowing: $showAnalysisOptions)
                            .padding(.bottom, 10)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showAnalysisOptions.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 48, height: 48)
                                .shadow(radius: 3)
                            
                            Image(systemName: showAnalysisOptions ? "xmark" : "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(showAnalysisOptions ? 45 : 0))
                        }
                    }
                    .padding(.bottom, 55)
                }
            }
        }
        .onChange(of: homeViewModel.shouldNavigateToAnalysis) { newValue in
            if newValue {
                selectedTab = 1
                homeViewModel.shouldNavigateToAnalysis = false
            }
        }
    }
}

#Preview {
    MainView()
} 