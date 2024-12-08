 
//
//  ContentView.swift
//  Whatsapp-Counter
//
//  Created by Sabri Çetin on 6.12.2024.
//


import SwiftUI

struct ContentView: View {
    @State private var isShowingPicker = false
    @State private var isShowingAlert = false

    var body: some View {
        VStack(spacing: 20) {
            // Dosya Seç Butonu
            Button("Dosya Seç") {
                isShowingPicker = true
            }
            .sheet(isPresented: $isShowingPicker) {
                DocumentPicker(types: [.pdf]) { url in
                    print("Seçilen dosya: \(url)")
                    isShowingPicker = false
                }
            }

            // Uyarı Göster Butonu
            Button("Uyarı Göster") {
                isShowingAlert = true
            }
            .alert(isPresented: $isShowingAlert) {
                Alert(
                    title: Text("Uyarı"),
                    message: Text("Bu bir uyarıdır."),
                    dismissButton: .default(Text("Tamam"))
                )
            }
        }
        .padding()
    }
}

/*
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
*/
