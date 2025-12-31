//
//  BBLogConstants.swift
//  BatteryBoi
//
//  Created by Claude on 12/30/25.
//

import Foundation
import OSLog

public enum LogLevel: String, CaseIterable {
    case debug = "Debug"
    case info = "Info"
    case notice = "Notice"
    case warning = "Warning"
    case error = "Error"
    case critical = "Critical"

    public init(from osLogLevel: OSLogEntryLog.Level) {
        switch osLogLevel {
            case .debug: self = .debug
            case .info: self = .info
            case .notice: self = .notice
            case .error: self = .error
            case .fault: self = .critical
            default: self = .info
        }
    }

    public var symbol: String {
        switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .notice: return "📌"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🔥"
        }
    }
}

public enum LogTimeRange {
    case last15Minutes
    case last30Minutes
    case lastHour
    case last6Hours
    case last24Hours
    case lastWeek
    case custom(TimeInterval)

    public var timeInterval: TimeInterval {
        switch self {
            case .last15Minutes: return -15 * 60
            case .last30Minutes: return -30 * 60
            case .lastHour: return -60 * 60
            case .last6Hours: return -6 * 60 * 60
            case .last24Hours: return -24 * 60 * 60
            case .lastWeek: return -7 * 24 * 60 * 60
            case .custom(let interval): return -abs(interval)
        }
    }
}

public struct LogEntry {
    public let date: Date
    public let category: String
    public let level: LogLevel
    public let message: String

    public init(date: Date, category: String, level: LogLevel, message: String) {
        self.date = date
        self.category = category
        self.level = level
        self.message = message
    }
}

public struct LogExportedObject: Equatable {
    public let date: Date
    public let url: URL

    public init(date: Date, url: URL) {
        self.date = date
        self.url = url
    }
}
