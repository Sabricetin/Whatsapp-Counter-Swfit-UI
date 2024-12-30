import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                // Ana sayfa içeriği
                Text("WhatsApp Sohbet Analizi")
                    .font(.title)
                    .padding()
                
                Image(systemName: "message.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Sohbet dosyanızı analiz etmek için alttaki + butonuna tıklayın")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle(Constants.Navigation.homeTitle)
        }
    }
} 