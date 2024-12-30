import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // Ayarlar içeriği buraya gelecek
            }
            .navigationTitle("Settings")
        }
    }
} 