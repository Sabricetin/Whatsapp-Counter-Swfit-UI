import Foundation
import ZIPFoundation

enum FileAnalyzerError: Error {
    case invalidFileFormat
    case fileReadError
    case parseError
    case unsupportedFileType
}

class FileAnalyzer {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "[dd.MM.yyyy HH:mm:ss]" // WhatsApp tarih formatı
        return formatter
    }()
    
    func analyzeFile(at url: URL) async throws -> AnalysisSummary {
        let fileExtension = url.pathExtension.lowercased()
        
        guard Constants.FileTypes.supportedExtensions.contains(fileExtension) else {
            throw FileAnalyzerError.unsupportedFileType
        }
        
        switch fileExtension {
        case "txt":
            return try await analyzeTxtFile(at: url)
        case "zip":
            return try await analyzeZipFile(at: url)
        default:
            throw FileAnalyzerError.unsupportedFileType
        }
    }
    
    private func analyzeTxtFile(at url: URL) async throws -> AnalysisSummary {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            throw FileAnalyzerError.fileReadError
        }
        
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty } // Boş satırları filtrele
        
        var participantMessages: [String: Int] = [:]
        var participantMedia: [String: Int] = [:]
        var dates = Set<String>() // Tarih string'lerini tut
        
        let messagePattern = try? NSRegularExpression(
            pattern: "\\[(\\d{2}\\.\\d{2}\\.\\d{4} \\d{2}:\\d{2}:\\d{2})\\] ([^:]+): (.*)",
            options: []
        )
        
        for line in lines {
            if let match = messagePattern?.firstMatch(
                in: line,
                options: [],
                range: NSRange(location: 0, length: line.utf16.count)
            ) {
                if let dateRange = Range(match.range(at: 1), in: line),
                   let nameRange = Range(match.range(at: 2), in: line),
                   let messageRange = Range(match.range(at: 3), in: line) {
                    
                    let dateStr = String(line[dateRange])
                    let name = String(line[nameRange]).trimmingCharacters(in: .whitespaces)
                    let message = String(line[messageRange])
                    
                    dates.insert(String(dateStr.prefix(10))) // Sadece tarihi al (saat olmadan)
                    participantMessages[name, default: 0] += 1
                    
                    if message.contains("<Media omitted>") || message.contains("‎<attached:") {
                        participantMedia[name, default: 0] += 1
                    }
                }
            }
        }
        
        let participantStats = participantMessages.map { name, count in
            ParticipantStat(
                id: UUID(),
                name: name,
                messageCount: count,
                mediaCount: participantMedia[name] ?? 0
            )
        }.sorted { $0.messageCount > $1.messageCount }
        
        return AnalysisSummary(
            totalMessages: participantMessages.values.reduce(0, +),
            totalMedia: participantMedia.values.reduce(0, +),
            activeDays: dates.count,
            totalParticipants: participantMessages.count,
            activeParticipants: participantMessages.filter { $0.value > 0 }.count,
            participantStats: participantStats
        )
    }
    
    private func analyzeZipFile(at url: URL) async throws -> AnalysisSummary {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }
        
        do {
            try fileManager.unzipItem(at: url, to: tempDir)
            
            // WhatsApp mesaj dosyasını bul
            let files = try fileManager.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension.lowercased() == "txt" }
            
            guard let chatFile = files.first else {
                throw FileAnalyzerError.invalidFileFormat
            }
            
            return try await analyzeTxtFile(at: chatFile)
        } catch CocoaError.fileReadNoPermission {
            throw FileAnalyzerError.fileReadError
        } catch {
            if error is FileAnalyzerError {
                throw error
            }
            throw FileAnalyzerError.invalidFileFormat
        }
    }
} 
