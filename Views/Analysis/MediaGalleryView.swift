import SwiftUI
import AVKit

struct MediaGalleryView: View {
    let mediaFiles: [MediaFile]
    @State private var selectedMedia: MediaFile?
    @State private var showingDetail = false
    @State private var showingAllMedia = false
    
    private var photoFiles: [MediaFile] {
        mediaFiles.filter { $0.type == .image }
    }
    
    private var gifFiles: [MediaFile] {
        mediaFiles.filter { $0.type == .gif }
    }
    
    private var videoFiles: [MediaFile] {
        mediaFiles.filter { $0.type == .video }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Medya İstatistikleri
            VStack(alignment: .leading, spacing: 12) {
                Text("Medya İstatistikleri")
                    .font(.headline)
                
                HStack {
                    StatItemView(
                        icon: "photo",
                        title: "Fotoğraflar",
                        value: "\(photoFiles.count)"
                    )
                    Spacer()
                    StatItemView(
                        icon: "gift",
                        title: "GIF'ler",
                        value: "\(gifFiles.count)"
                    )
                    Spacer()
                    StatItemView(
                        icon: "video",
                        title: "Videolar",
                        value: "\(videoFiles.count)"
                    )
                }
                
                let totalSize = ByteCountFormatter.string(
                    fromByteCount: mediaFiles.reduce(0) { $0 + $1.size },
                    countStyle: .file
                )
                
                StatItemView(
                    icon: "internaldrive",
                    title: "Toplam Boyut",
                    value: totalSize
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
            
            ScrollView {
                // Fotoğraflar
                if !photoFiles.isEmpty {
                    MediaPreviewCard(
                        title: "Fotoğraflar",
                        icon: "photo",
                        files: photoFiles,
                        onMediaTap: { selectedMedia = $0 },
                        onShowAll: { showingAllMedia = true }
                    )
                }
                
                // GIF'ler
                if !gifFiles.isEmpty {
                    MediaPreviewCard(
                        title: "GIF'ler",
                        icon: "gift",
                        files: gifFiles,
                        onMediaTap: { selectedMedia = $0 },
                        onShowAll: { showingAllMedia = true }
                    )
                }
                
                // Videolar
                if !videoFiles.isEmpty {
                    MediaPreviewCard(
                        title: "Videolar",
                        icon: "video",
                        files: videoFiles,
                        onMediaTap: { selectedMedia = $0 },
                        onShowAll: { showingAllMedia = true }
                    )
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let media = selectedMedia {
                MediaDetailView(file: media)
            }
        }
        .sheet(isPresented: $showingAllMedia) {
            NavigationView {
                AllMediaView(mediaFiles: mediaFiles)
            }
        }
    }
}

struct MediaPreviewCard: View {
    let title: String
    let icon: String
    let files: [MediaFile]
    let onMediaTap: (MediaFile) -> Void
    let onShowAll: () -> Void
    
    private var previewFiles: [MediaFile] {
        Array(files.prefix(6))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
                Text("\(files.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(previewFiles) { file in
                    MediaThumbnailView(file: file)
                        .frame(height: 80)
                        .onTapGesture {
                            onMediaTap(file)
                        }
                }
            }
            
            if files.count > 6 {
                Button(action: onShowAll) {
                    HStack {
                        Text("Tümünü Gör")
                            .font(.subheadline)
                        Spacer()
                        Text("+\(files.count - 6)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct StatItemView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .bold()
            }
        }
    }
}

struct AllMediaView: View {
    let mediaFiles: [MediaFile]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMedia: MediaFile?
    @State private var showingDetail = false
    @State private var searchText = ""
    @State private var selectedType: MediaType?
    @State private var currentPage = 1
    private let itemsPerPage = 20
    
    private var filteredFiles: [MediaFile] {
        mediaFiles.filter { file in
            let matchesSearch = searchText.isEmpty || 
                file.participant.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedType == nil || file.type == selectedType
            return matchesSearch && matchesType
        }
    }
    
    private var paginatedFiles: [MediaFile] {
        let endIndex = min(currentPage * itemsPerPage, filteredFiles.count)
        return Array(filteredFiles[0..<endIndex])
    }
    
    private var hasMorePages: Bool {
        currentPage * itemsPerPage < filteredFiles.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filtreler
            VStack(spacing: 8) {
                TextField("Katılımcı ara...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Picker("Medya Tipi", selection: $selectedType) {
                    Text("Tümü").tag(Optional<MediaType>.none)
                    Text("Fotoğraflar").tag(Optional<MediaType>.some(.image))
                    Text("GIF'ler").tag(Optional<MediaType>.some(.gif))
                    Text("Videolar").tag(Optional<MediaType>.some(.video))
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
            
            // Medya Listesi
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 8)
                ], spacing: 8) {
                    ForEach(paginatedFiles) { file in
                        MediaThumbnailView(file: file)
                            .onTapGesture {
                                selectedMedia = file
                                showingDetail = true
                            }
                    }
                }
                .padding(8)
                
                if hasMorePages {
                    Button(action: {
                        currentPage += 1
                    }) {
                        Text("Daha Fazla Göster")
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kapat") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let media = selectedMedia {
                MediaDetailView(file: media)
            }
        }
        .onChange(of: searchText) { _ in
            currentPage = 1
        }
        .onChange(of: selectedType) { _ in
            currentPage = 1
        }
    }
    
    private var navigationTitle: String {
        if let selectedType = selectedType {
            switch selectedType {
            case .image:
                return "Fotoğraflar"
            case .gif:
                return "GIF'ler"
            case .video:
                return "Videolar"
            case .unknown:
                return "Tüm Medyalar"
            }
        } else {
            return "Tüm Medyalar"
        }
    }
}

struct MediaThumbnailView: View {
    let file: MediaFile
    @State private var thumbnail: UIImage?
    @State private var loadError = false
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
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
            } else if loadError {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                    Text("Yüklenemedi")
                        .font(.caption)
                }
                .frame(width: 100, height: 100)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
            do {
                // Önbellekten kontrol et
                if let cachedImage = Self.imageCache.object(forKey: file.id.uuidString as NSString) {
                    await MainActor.run {
                        thumbnail = cachedImage
                    }
                    return
                }
                
                if file.type == .image || file.type == .gif {
                    guard let data = try? Data(contentsOf: file.url) else {
                        await MainActor.run {
                            loadError = true
                        }
                        return
                    }
                    
                    guard let image = UIImage(data: data) else {
                        await MainActor.run {
                            loadError = true
                        }
                        return
                    }
                    
                    // Thumbnail oluştur
                    let size = CGSize(width: 200, height: 200)
                    let renderer = UIGraphicsImageRenderer(size: size)
                    let thumbnailImage = renderer.image { context in
                        image.draw(in: CGRect(origin: .zero, size: size))
                    }
                    
                    // Önbelleğe kaydet
                    Self.imageCache.setObject(thumbnailImage, forKey: file.id.uuidString as NSString)
                    
                    await MainActor.run {
                        thumbnail = thumbnailImage
                    }
                } else if file.type == .video {
                    let asset = AVAsset(url: file.url)
                    let imageGenerator = AVAssetImageGenerator(asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    
                    do {
                        let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                        let uiImage = UIImage(cgImage: cgImage)
                        
                        // Thumbnail oluştur
                        let size = CGSize(width: 200, height: 200)
                        let renderer = UIGraphicsImageRenderer(size: size)
                        let thumbnailImage = renderer.image { context in
                            uiImage.draw(in: CGRect(origin: .zero, size: size))
                        }
                        
                        // Önbelleğe kaydet
                        Self.imageCache.setObject(thumbnailImage, forKey: file.id.uuidString as NSString)
                        
                        await MainActor.run {
                            thumbnail = thumbnailImage
                        }
                    } catch {
                        await MainActor.run {
                            loadError = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    loadError = true
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