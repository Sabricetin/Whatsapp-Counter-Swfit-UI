import SwiftUI
import AVKit

struct MediaGalleryView: View {
    let mediaFiles: [MediaFile]
    @State private var selectedMedia: MediaFile?
    @State private var showingDetail = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(mediaFiles, id: \.id) { file in
                    MediaThumbnailView(file: file)
                        .onTapGesture {
                            selectedMedia = file
                            showingDetail = true
                        }
                }
            }
            .padding(8)
        }
        .sheet(isPresented: $showingDetail) {
            if let media = selectedMedia {
                MediaDetailView(file: media)
            }
        }
    }
}

struct MediaThumbnailView: View {
    let file: MediaFile
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        file.type == .video ?
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                        : nil
                    )
            } else {
                ProgressView()
                    .frame(width: 100, height: 100)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        Task {
            if file.type == .image {
                if let data = try? Data(contentsOf: file.url),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        thumbnail = image
                    }
                }
            } else if file.type == .video {
                let asset = AVAsset(url: file.url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                do {
                    let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                    await MainActor.run {
                        thumbnail = UIImage(cgImage: cgImage)
                    }
                } catch {
                    print("Error generating thumbnail: \(error)")
                }
            }
        }
    }
}

struct MediaDetailView: View {
    let file: MediaFile
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if file.type == .image {
                    ImageDetailView(url: file.url)
                } else {
                    VideoDetailView(url: file.url)
                }
            }
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ImageDetailView: View {
    let url: URL
    
    var body: some View {
        if let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
        } else {
            Text("Resim yüklenemedi")
                .foregroundColor(.secondary)
        }
    }
}

struct VideoDetailView: View {
    let url: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .edgesIgnoringSafeArea(.all)
    }
} 