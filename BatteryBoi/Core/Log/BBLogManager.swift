//
//  BatteryBoi
//
//  Created by Claude on 12/30/25.
//

import Foundation
import OSLog
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import Combine

public class LogManager: ObservableObject {
    public static let shared = LogManager()

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.batteryboi"
    private var loggers: [String: Logger] = [:]
    private let queue = DispatchQueue(label: "com.batteryboi.logmanager", attributes: .concurrent)

    @Published private(set) var exporting: Bool = false
    @Published private(set) var exported: LogExportedObject?

    init() {
        if let url = UserDefaults.standard.url(forKey: "appLogExport"), let date = UserDefaults.standard.object(forKey: "appLogExport_timestamp") as? Date {
            self.exported = LogExportedObject(date: date, url: url)
        }
    }

    public func log(_ message: String, level: LogLevel = .info, category: String? = nil, file: String = #file) {
        let categoryName = category ?? self.logExtractClassName(from: file)
        let logger = self.logGetLogger(for: categoryName)

        switch level {
            case .debug: logger.debug("\(message)")
            case .info: logger.info("\(message)")
            case .notice: logger.notice("\(message)")
            case .warning: logger.warning("\(message)")
            case .error: logger.error("\(message)")
            case .critical: logger.critical("\(message)")
        }
    }

    public func logDebug(_ message: String, category: String? = nil, file: String = #file) {
        self.log(message, level: .debug, category: category, file: file)
    }

    public func logInfo(_ message: String, category: String? = nil, file: String = #file) {
        self.log(message, level: .info, category: category, file: file)
    }

    public func logNotice(_ message: String, category: String? = nil, file: String = #file) {
        self.log(message, level: .notice, category: category, file: file)
    }

    public func logWarning(_ message: String, category: String? = nil, file: String = #file) {
        self.log(message, level: .warning, category: category, file: file)
    }

    public func logError(_ message: String, category: String? = nil, file: String = #file) {
        self.log(message, level: .error, category: category, file: file)
    }

    public func logCritical(_ message: String, category: String? = nil, file: String = #file) {
        self.log(message, level: .critical, category: category, file: file)
    }

    public func logExport(timeRange: LogTimeRange = .last24Hours, levels: [LogLevel] = LogLevel.allCases, categories: [String]? = nil) async throws -> URL {
        guard self.exporting == false else {
            throw AppError(.rickSanity, message: "Export already in progress")
			
        }

        await MainActor.run {
            self.exporting = true
        }

        defer {
            Task { @MainActor in
                self.exporting = false
            }
        }

        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(timeIntervalSinceLatestBoot: timeRange.timeInterval)
            let entries = try store.getEntries(at: position)

            let filteredEntries = entries.compactMap { entry -> LogEntry? in
                guard let logEntry = entry as? OSLogEntryLog else {
                    return nil
                }

                guard logEntry.subsystem == self.subsystem else {
                    return nil
                }

                if let categories = categories, categories.contains(logEntry.category) == false {
                    return nil
                }

                let level = LogLevel(from: logEntry.level)
                guard levels.contains(level) == true else {
                    return nil
                }

                return LogEntry(date: logEntry.date, category: logEntry.category, level: level, message: logEntry.composedMessage)
            }

            let url = try await self.logSaveToFile(filteredEntries)

            await MainActor.run {
                UserDefaults.standard.set(url, forKey: "appLogExport")
                UserDefaults.standard.set(Date(), forKey: "appLogExport_timestamp")
                if let date = UserDefaults.standard.object(forKey: "appLogExport_timestamp") as? Date {
                    self.exported = LogExportedObject(date: date, url: url)
                }
            }

            return url
        }
        catch {
            throw error
        }
    }

    public func logExportToDocuments(filename: String? = nil, timeRange: LogTimeRange = .last24Hours, levels: [LogLevel] = LogLevel.allCases, categories: [String]? = nil) async throws -> URL {
        let exportURL = try await self.logExport(timeRange: timeRange, levels: levels, categories: categories)

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AppError(.funkeMobile, message: "Could not access documents directory")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = filename ?? "BatteryBoi-Logs-\(formatter.string(from: Date())).txt"
        let destinationURL = documentsURL.appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: destinationURL.path) == true {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: exportURL, to: destinationURL)

        return destinationURL
    }

    public func logShare(timeRange: LogTimeRange = .last24Hours, levels: [LogLevel] = LogLevel.allCases, categories: [String]? = nil) async throws -> URL {
        return try await self.logExport(timeRange: timeRange, levels: levels, categories: categories)
    }

    public func logResponse(_ jsonObject: Any) throws -> URL {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw AppError(.mcpoylesMilk, message: "Could not encode JSON response data")
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let filename = "response-\(UUID().uuidString).json"
        let fileURL = tempDirectory.appendingPathComponent(filename)

        try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    public func logClearExported() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let logFiles = files.filter { $0.lastPathComponent.hasPrefix("BatteryBoi-Logs-") && $0.pathExtension == "txt" }

            for file in logFiles {
                try FileManager.default.removeItem(at: file)
            }
        }
        catch {
            self.logError("Failed to clear exported logs: \(error.localizedDescription)", category: "LogManager")
        }
    }

    public func logGetExportedFiles() -> [URL] {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.creationDateKey])
            let logFiles = files.filter { $0.lastPathComponent.hasPrefix("BatteryBoi-Logs-") && $0.pathExtension == "txt" }

            return logFiles.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
        }
        catch {
            self.logError("Failed to get exported log files: \(error.localizedDescription)", category: "LogManager")
            return []
        }
    }

    private func logGetLogger(for category: String) -> Logger {
        return queue.sync(flags: .barrier) {
            if let existingLogger = self.loggers[category] {
                return existingLogger
            }

            let logger = Logger(subsystem: self.subsystem, category: category)

            self.loggers[category] = logger

            return logger
        }
    }

    nonisolated private func logExtractClassName(from filePath: String) -> String {
        let filename = (filePath as NSString).lastPathComponent
        let file = (filename as NSString).deletingPathExtension

        return file
    }

    private func logSaveToFile(_ entries: [LogEntry]) async throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        var content = "BatteryBoi Logs Export\n"
        content += "Generated: \(formatter.string(from: Date()))\n"
        content += "Total Entries: \(entries.count)\n"
        content += String(repeating: "=", count: 80) + "\n\n"

        for entry in entries {
            let timestamp = formatter.string(from: entry.date)
            let levelSymbol = entry.level.symbol
            content += "[\(timestamp)] \(levelSymbol) [\(entry.category)] \(entry.message)\n"
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let filename = "BatteryBoi-Logs-\(UUID().uuidString).txt"
        let fileURL = tempDirectory.appendingPathComponent(filename)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }
}
