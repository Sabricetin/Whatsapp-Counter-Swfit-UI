import SwiftUI

struct WordEmojiAnalysisView: View {
    let emojiStats: EmojiStats
    let wordStats: WordStats
    @State private var selectedTab = 0
    @State private var isFilterEnabled = true
    
    // Filtrelenecek kelimeler
    private let filteredWords = Set([
         "dahil" , "edilmedi" , "görüntü" , "i" ,
         "gif" , "çıkartma" , "arama" , "görüntülü" ,
    ])
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Analiz Tipi", selection: $selectedTab) {
                Text("Emojiler").tag(0)
                Text("Kelimeler").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if selectedTab == 0 {
                EmojiAnalysisView(stats: emojiStats)
            } else {
                WordAnalysisView(
                    stats: wordStats,
                    isFilterEnabled: $isFilterEnabled,
                    filteredWords: filteredWords
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EmojiAnalysisView: View {
    let stats: EmojiStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("En Çok Kullanılan Emojiler")
                .font(.headline)
            
            Text("Toplam: \(stats.totalCount) emoji")
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(stats.topEmojis) { emoji in
                        HStack {
                            Text(emoji.emoji)
                                .font(.title2)
                            Text("\(emoji.count)x")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", emoji.percentage))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxHeight: 200)
            
            if !stats.emojisByParticipant.isEmpty {
                Text("Kişi Bazlı Emoji Kullanımı")
                    .font(.headline)
                    .padding(.top, 16)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(stats.emojisByParticipant.keys.sorted()), id: \.self) { participant in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(participant)
                                    .font(.subheadline)
                                    .bold()
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(stats.emojisByParticipant[participant] ?? []) { emoji in
                                            VStack(spacing: 2) {
                                                Text(emoji.emoji)
                                                    .font(.title3)
                                                Text("\(emoji.count)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
}

struct WordAnalysisView: View {
    let stats: WordStats
    @Binding var isFilterEnabled: Bool
    let filteredWords: Set<String>
    
    private var filteredTopWords: [WordStat] {
        if isFilterEnabled {
            return stats.topWords.filter { !filteredWords.contains($0.word.lowercased()) }
        }
        return stats.topWords
    }
    
    private func filterParticipantWords(_ words: [WordStat]) -> [WordStat] {
        if isFilterEnabled {
            return words.filter { !filteredWords.contains($0.word.lowercased()) }
        }
        return words
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("En Çok Kullanılan Kelimeler")
                    .font(.headline)
                Spacer()
                Toggle("Filtre", isOn: $isFilterEnabled)
                    .labelsHidden()
            }
            
            Text("Toplam: \(stats.totalCount) kelime (\(stats.uniqueCount) benzersiz)")
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            if isFilterEnabled {
                Text("Bağlaçlar ve yaygın kelimeler filtreleniyor")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredTopWords) { word in
                        HStack {
                            Text(word.word)
                                .font(.body)
                            Text("\(word.count)x")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", word.percentage))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxHeight: 200)
            
            if !stats.wordsByParticipant.isEmpty {
                Text("Kişi Bazlı Kelime Kullanımı")
                    .font(.headline)
                    .padding(.top, 16)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(stats.wordsByParticipant.keys.sorted()), id: \.self) { participant in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(participant)
                                    .font(.subheadline)
                                    .bold()
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(filterParticipantWords(stats.wordsByParticipant[participant] ?? [])) { word in
                                            VStack(spacing: 2) {
                                                Text(word.word)
                                                    .font(.callout)
                                                Text("\(word.count)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }
            
            FlexibleViewContent(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

struct FlexibleViewContent<Data: Collection, Content: View>: View where Data.Element: Identifiable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastHeight = CGFloat.zero
        
        return GeometryReader { geometry in
            ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, element in
                    content(element)
                        .padding([.horizontal, .vertical], spacing)
                        .alignmentGuide(alignment, computeValue: { dimension in
                            if abs(width - dimension.width) > geometry.size.width {
                                width = 0
                                height -= lastHeight
                            }
                            lastHeight = dimension.height
                            let result = width
                            if index == data.count - 1 {
                                width = 0
                            } else {
                                width -= dimension.width
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in
                            let result = height
                            if index == data.count - 1 {
                                height = 0
                            }
                            return result
                        })
                }
            }
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
} 
