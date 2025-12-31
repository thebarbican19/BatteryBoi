//
//  BBLogManagerTests.swift
//  BatteryBoiTests
//
//  Created by Claude on 12/30/25.
//

import XCTest
import OSLog
@testable import BatteryBoi

final class BBLogManagerTests: XCTestCase {

    var logManager: LogManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        logManager = LogManager.shared
    }

    override func tearDownWithError() throws {
        logManager = nil
        try super.tearDownWithError()
    }

    func testLogManagerSingleton() throws {
        let instance1 = LogManager.shared
        let instance2 = LogManager.shared

        XCTAssertTrue(instance1 === instance2, "LogManager should be a singleton")
    }

    func testLogLevelsExecuteWithoutCrashing() throws {
        XCTAssertNoThrow(logManager.logDebug("Test debug message"))
        XCTAssertNoThrow(logManager.logInfo("Test info message"))
        XCTAssertNoThrow(logManager.logNotice("Test notice message"))
        XCTAssertNoThrow(logManager.logWarning("Test warning message"))
        XCTAssertNoThrow(logManager.logError("Test error message"))
        XCTAssertNoThrow(logManager.logCritical("Test critical message"))
    }

    func testLogLevelSymbols() throws {
        XCTAssertEqual(LogLevel.debug.symbol, "🔍")
        XCTAssertEqual(LogLevel.info.symbol, "ℹ️")
        XCTAssertEqual(LogLevel.notice.symbol, "📌")
        XCTAssertEqual(LogLevel.warning.symbol, "⚠️")
        XCTAssertEqual(LogLevel.error.symbol, "❌")
        XCTAssertEqual(LogLevel.critical.symbol, "🔥")
    }

    func testLogTimeRangeIntervals() throws {
        XCTAssertEqual(LogTimeRange.last15Minutes.timeInterval, -15 * 60)
        XCTAssertEqual(LogTimeRange.last30Minutes.timeInterval, -30 * 60)
        XCTAssertEqual(LogTimeRange.lastHour.timeInterval, -60 * 60)
        XCTAssertEqual(LogTimeRange.last6Hours.timeInterval, -6 * 60 * 60)
        XCTAssertEqual(LogTimeRange.last24Hours.timeInterval, -24 * 60 * 60)
        XCTAssertEqual(LogTimeRange.lastWeek.timeInterval, -7 * 24 * 60 * 60)
    }

    func testLogTimeRangeCustomInterval() throws {
        let customInterval: TimeInterval = 3600
        let range = LogTimeRange.custom(customInterval)

        XCTAssertEqual(range.timeInterval, -3600)
    }

    func testLogExportInitialState() throws {
        XCTAssertFalse(logManager.exporting, "Should not be exporting initially")
    }

    func testLogExportCreatesFile() async throws {
        logManager.logInfo("Test log entry for export")

        let url = try await logManager.logExport(timeRange: .last15Minutes)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Log file should exist")
        XCTAssertTrue(url.lastPathComponent.hasPrefix("BatteryBoi-Logs-"), "Log file should have correct prefix")
        XCTAssertEqual(url.pathExtension, "txt", "Log file should be a text file")

        try? FileManager.default.removeItem(at: url)
    }

    func testLogExportContent() async throws {
        let testMessage = "Test log entry \(UUID().uuidString)"
        logManager.logInfo(testMessage)

        let url = try await logManager.logExport(timeRange: .last15Minutes)

        let content = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(content.contains("BatteryBoi Logs Export"), "Should contain export header")
        XCTAssertTrue(content.contains("Total Entries:"), "Should contain entry count")

        try? FileManager.default.removeItem(at: url)
    }

    func testLogExportThrowsWhenAlreadyExporting() async throws {
        logManager.logInfo("Test entry")

        Task {
            _ = try? await logManager.logExport(timeRange: .last15Minutes)
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        do {
            _ = try await logManager.logExport(timeRange: .last15Minutes)
            XCTFail("Should throw error when already exporting")
        }
        catch let error as BBAppError {
            XCTAssertEqual(error.code, .bobLoblaw, "Should throw bobLoblaw error")
        }
    }

    func testLogResponseCreatesJSONFile() throws {
        let testData: [String: Any] = [
            "test": "value",
            "number": 42,
            "nested": ["key": "value"]
        ]

        let url = try logManager.logResponse(testData)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "JSON file should exist")
        XCTAssertEqual(url.pathExtension, "json", "File should be JSON")
        XCTAssertTrue(url.lastPathComponent.hasPrefix("response-"), "File should have correct prefix")

        try? FileManager.default.removeItem(at: url)
    }

    func testLogClearExportedRemovesFiles() throws {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not get documents directory")
            return
        }

        let testFileURL = documentsURL.appendingPathComponent("BatteryBoi-Logs-test.txt")
        try "Test content".write(to: testFileURL, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))

        logManager.logClearExported()

        XCTAssertFalse(FileManager.default.fileExists(atPath: testFileURL.path), "Test file should be removed")
    }

    func testLogGetExportedFilesReturnsCorrectFiles() throws {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("Could not get documents directory")
            return
        }

        let testFile1 = documentsURL.appendingPathComponent("BatteryBoi-Logs-test1.txt")
        let testFile2 = documentsURL.appendingPathComponent("BatteryBoi-Logs-test2.txt")

        try "Test 1".write(to: testFile1, atomically: true, encoding: .utf8)
        try "Test 2".write(to: testFile2, atomically: true, encoding: .utf8)

        let files = logManager.logGetExportedFiles()

        XCTAssertGreaterThanOrEqual(files.count, 2, "Should find at least 2 test files")

        logManager.logClearExported()
    }

    func testConcurrentLogging() throws {
        let expectation = XCTestExpectation(description: "Concurrent logging completes")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { index in
            logManager.logInfo("Concurrent log \(index)")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
