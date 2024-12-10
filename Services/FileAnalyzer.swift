import Foundation
import OSLog
import ZIPFoundation

enum FileAnalyzerError: Error {
    case fileReadError
    case unsupportedFileType
    case parseError
    case invalidFileFormat
    case zipExtractionError
    case containsMediaFiles
}

class FileAnalyzer {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WhatsApp-Counter", category: "FileAnalyzer")
    private let emojiPattern = try! NSRegularExpression(pattern: "[\\p{Emoji_Presentation}\\p{Emoji_Modifier_Base}\\p{Emoji_Modifier}\\p{Emoji_Component}]+", options: [])
    private let wordPattern = try! NSRegularExpression(pattern: "[\\p{L}\\p{N}']+", options: [])
    
    private let mediaExtensions = ["jpg", "jpeg", "png", "gif", "mp4", "mov", "mp3", "wav", "webp", "heic"]
    
    private func checkForMediaFiles(in directory: URL) throws -> Bool {
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                let fileExtension = fileURL.pathExtension.lowercased()
                if mediaExtensions.contains(fileExtension) {
                    return true
                }
            }
        }
        return false
    }
    
    func analyzeFile(at url: URL, allowMedia: Bool = false) async throws -> AnalysisSummary {
        logger.info("Starting analysis of file: \(url.lastPathComponent)")
        
        let fileExtension = url.pathExtension.lowercased()
        
        guard Constants.FileTypes.supportedExtensions.contains(fileExtension) else {
            logger.error("Unsupported file type: \(fileExtension)")
            throw FileAnalyzerError.unsupportedFileType
        }
        
        let content: String
        let chatName = url.deletingPathExtension().lastPathComponent
        
        if fileExtension == "zip" {
            let (extractedContent, hasMedia) = try await extractAndCheckZipFile(at: url)
            
            if hasMedia && !allowMedia {
                logger.error("ZIP file contains media files but media is not allowed")
                throw FileAnalyzerError.containsMediaFiles
            }
            
            content = extractedContent
        } else {
            do {
                content = try String(contentsOf: url, encoding: .utf8)
                logger.info("Successfully read text file content")
            } catch {
                logger.error("Failed to read text file: \(error.localizedDescription)")
                throw FileAnalyzerError.fileReadError
            }
        }
        
        var analysis = try await analyzeContent(content)
        analysis.chatName = chatName
        return analysis
    }
    
    private func extractAndCheckZipFile(at url: URL) async throws -> (content: String, hasMedia: Bool) {
        logger.info("Extracting ZIP file")
        
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            defer {
                try? fileManager.removeItem(at: tempDir)
            }
            
            logger.info("Created temporary directory: \(tempDir.lastPathComponent)")
            
            try fileManager.unzipItem(at: url, to: tempDir)
            logger.info("Successfully unzipped file")
            
            let hasMedia = try checkForMediaFiles(in: tempDir)
            
            let files = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension.lowercased() == "txt" }
            
            guard let chatFile = files.first else {
                logger.error("No text file found in ZIP archive")
                throw FileAnalyzerError.invalidFileFormat
            }
            
            logger.info("Found chat file: \(chatFile.lastPathComponent)")
            
            let content = try String(contentsOf: chatFile, encoding: .utf8)
            logger.info("Successfully read chat file content")
            
            return (content, hasMedia)
            
        } catch {
            logger.error("Failed to process ZIP file: \(error.localizedDescription)")
            throw FileAnalyzerError.zipExtractionError
        }
    }
    
    private func analyzeContent(_ content: String) async throws -> AnalysisSummary {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        logger.info("Found \(lines.count) non-empty lines")
        
        var participants: [String: [String]] = [:]
        var dailyMessages: [String: Int] = [:]
        var hourlyMessages: [Int: Int] = [:]
        var emojiCounts: [String: [String: Int]] = [:]
        var wordCounts: [String: [String: Int]] = [:]
        
        var startDate: Date?
        var endDate: Date?
        var parsedLines = 0
        
        for line in lines {
            if let (date, participant, message) = parseLine(line) {
                parsedLines += 1
                
                if startDate == nil || date < startDate! {
                    startDate = date
                }
                if endDate == nil || date > endDate! {
                    endDate = date
                }
                
                if participants[participant] == nil {
                    participants[participant] = []
                }
                participants[participant]?.append(message)
                
                let dayKey = formatDate(date)
                dailyMessages[dayKey, default: 0] += 1
                
                let hour = Calendar.current.component(.hour, from: date)
                hourlyMessages[hour, default: 0] += 1
                
                let emojis = findEmojis(in: message)
                if !emojis.isEmpty {
                    if emojiCounts[participant] == nil {
                        emojiCounts[participant] = [:]
                    }
                    for emoji in emojis {
                        emojiCounts[participant]?[emoji, default: 0] += 1
                    }
                }
                
                let words = findWords(in: message.lowercased())
                if !words.isEmpty {
                    if wordCounts[participant] == nil {
                        wordCounts[participant] = [:]
                    }
                    for word in words {
                        wordCounts[participant]?[word, default: 0] += 1
                    }
                }
            }
        }
        
        logger.info("Successfully parsed \(parsedLines) lines out of \(lines.count)")
        
        guard !participants.isEmpty else {
            logger.error("No valid messages found in the file")
            throw FileAnalyzerError.parseError
        }
        
        logger.info("Found \(participants.count) participants")
        
        let participantStats = participants.map { name, messages in
            let totalEmojis = (emojiCounts[name] ?? [:]).values.reduce(0, +)
            let totalWords = (wordCounts[name] ?? [:]).values.reduce(0, +)
            let avgLength = Double(messages.joined().count) / Double(messages.count)
            
            return ParticipantStat(
                id: UUID(),
                name: name,
                messageCount: messages.count,
                wordCount: totalWords,
                emojiCount: totalEmojis,
                averageMessageLength: avgLength,
                mostUsedEmojis: getTopEmojis(from: emojiCounts[name] ?? [:], total: totalEmojis),
                mostUsedWords: getTopWords(from: wordCounts[name] ?? [:], total: totalWords)
            )
        }.sorted { $0.messageCount > $1.messageCount }
        
        let allEmojis = emojiCounts.values.reduce(into: [String: Int]()) { result, participantEmojis in
            for (emoji, count) in participantEmojis {
                result[emoji, default: 0] += count
            }
        }
        let totalEmojis = allEmojis.values.reduce(0, +)
        
        let allWords = wordCounts.values.reduce(into: [String: Int]()) { result, participantWords in
            for (word, count) in participantWords {
                result[word, default: 0] += count
            }
        }
        let totalWords = allWords.values.reduce(0, +)
        
        logger.info("Analysis completed successfully")
        
        return AnalysisSummary(
            totalMessages: participants.values.map { $0.count }.reduce(0, +),
            totalWords: totalWords,
            timeRange: DateRange(start: startDate ?? Date(), end: endDate ?? Date()),
            participantStats: participantStats,
            dailyStats: createDailyStats(from: dailyMessages),
            hourlyStats: createHourlyStats(from: hourlyMessages),
            emojiStats: EmojiStats(
                totalCount: totalEmojis,
                topEmojis: getTopEmojis(from: allEmojis, total: totalEmojis),
                emojisByParticipant: emojiCounts.mapValues { getTopEmojis(from: $0, total: $0.values.reduce(0, +)) }
            ),
            wordStats: WordStats(
                totalCount: totalWords,
                uniqueCount: allWords.count,
                topWords: getTopWords(from: allWords, total: totalWords),
                wordsByParticipant: wordCounts.mapValues { getTopWords(from: $0, total: $0.values.reduce(0, +)) }
            )
        )
    }
    
    private func parseLine(_ line: String) -> (Date, String, String)? {
        let messagePattern = try? NSRegularExpression(
            pattern: "\\[(\\d{2}\\.\\d{2}\\.\\d{4} \\d{2}:\\d{2}:\\d{2})\\] ([^:]+): (.*)",
            options: []
        )
        
        guard let match = messagePattern?.firstMatch(
            in: line,
            options: [],
            range: NSRange(location: 0, length: line.utf16.count)
        ) else {
            logger.debug("Failed to match line pattern: \(line)")
            return nil
        }
        
        guard let dateRange = Range(match.range(at: 1), in: line),
              let nameRange = Range(match.range(at: 2), in: line),
              let messageRange = Range(match.range(at: 3), in: line) else {
            logger.debug("Failed to extract ranges from match")
            return nil
        }
        
        let dateStr = String(line[dateRange])
        let name = String(line[nameRange]).trimmingCharacters(in: .whitespaces)
        let message = String(line[messageRange])
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "tr_TR")
        
        guard let date = dateFormatter.date(from: dateStr) else {
            logger.debug("Failed to parse date: \(dateStr)")
            return nil
        }
        
        return (date, name, message)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func findEmojis(in text: String) -> [String] {
        let range = NSRange(text.startIndex..., in: text)
        return emojiPattern.matches(in: text, range: range).map { match in
            String(text[Range(match.range, in: text)!])
        }
    }
    
    private func findWords(in text: String) -> [String] {
        let range = NSRange(text.startIndex..., in: text)
        return wordPattern.matches(in: text, range: range).map { match in
            String(text[Range(match.range, in: text)!])
        }
    }
    
    private func getTopEmojis(from counts: [String: Int], total: Int) -> [EmojiStat] {
        return counts.map { emoji, count in
            EmojiStat(
                id: UUID(),
                emoji: emoji,
                count: count,
                percentage: Double(count) / Double(total) * 100
            )
        }
        .sorted { $0.count > $1.count }
        .prefix(10)
        .map { $0 }
    }
    
    private func getTopWords(from counts: [String: Int], total: Int) -> [WordStat] {
        return counts.map { word, count in
            WordStat(
                id: UUID(),
                word: word,
                count: count,
                percentage: Double(count) / Double(total) * 100
            )
        }
        .sorted { $0.count > $1.count }
        .prefix(20)
        .map { $0 }
    }
    
    private func createDailyStats(from dailyMessages: [String: Int]) -> [DailyStats] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        return dailyMessages.map { dateString, count in
            DailyStats(
                id: UUID(),
                date: dateFormatter.date(from: dateString) ?? Date(),
                messageCount: count
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func createHourlyStats(from hourlyMessages: [Int: Int]) -> [HourlyStats] {
        return (0...23).map { hour in
            HourlyStats(
                id: UUID(),
                hour: hour,
                messageCount: hourlyMessages[hour] ?? 0
            )
        }
    }
} 
