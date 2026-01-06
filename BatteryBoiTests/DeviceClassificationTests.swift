//
//  DeviceClassificationTests.swift
//  BatteryBoiTests
//
//  Created by Claude Code on 01/05/25.
//

import XCTest
@testable import BatteryBoi

final class DeviceClassificationTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func testClassifyMagicMouse() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "MagicMouse2,1", vendor: "Apple Inc", appearance: nil, hardware: nil, name: "Magic Mouse")

        XCTAssertEqual(result.category, .mouse)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.90)
        XCTAssertFalse(result.summary.isEmpty)
    }

    func testClassifyAirPodsPro() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "AirPods Pro", vendor: "Apple Inc", appearance: nil, hardware: nil, name: "AirPods Pro")

        XCTAssertEqual(result.category, .earbuds)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.90)
        XCTAssertFalse(result.summary.isEmpty)
    }

    func testClassifyNUTTracker() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "NUT", vendor: "Nutale Technology", appearance: nil, hardware: nil, name: "NUT 008A")

        XCTAssertEqual(result.category, .tracker)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.85)
        XCTAssertFalse(result.summary.isEmpty)
    }

    func testClassifyLogitechMX() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "MX Master 3", vendor: "Logitech", appearance: nil, hardware: nil, name: "MX Master 3")

        XCTAssertEqual(result.category, .mouse)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.85)
        XCTAssertFalse(result.summary.isEmpty)
    }

    func testClassifyByAppearanceCode_Mouse() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "Unknown", vendor: nil, appearance: "03C2", hardware: nil, name: "Unknown Device")

        XCTAssertEqual(result.category, .mouse)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.90)
    }

    func testClassifyByAppearanceCode_Keyboard() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "Unknown", vendor: nil, appearance: "03C1", hardware: nil, name: "Unknown Device")

        XCTAssertEqual(result.category, .keyboard)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.90)
    }

    func testClassifyByAppearanceCode_Earbuds() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "Unknown", vendor: nil, appearance: "0843", hardware: nil, name: "Unknown Device")

        XCTAssertEqual(result.category, .earbuds)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.90)
    }

    func testClassifyUnknownDevice() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "UNKNOWN_DEVICE_XYZ", vendor: "UnknownVendor", appearance: nil, hardware: nil, name: "Mystery Device")

        XCTAssertEqual(result.category, .unknown)
        XCTAssertLessThanOrEqual(result.confidence, 0.5)
        XCTAssertFalse(result.summary.isEmpty)
    }

    func testCachingBehavior() async throws {
        let model = "TestDevice123"
        let vendor = "TestVendor"

        let result1 = await ClassificationManager.shared.classifyDevice(model: model, vendor: vendor, appearance: nil, hardware: nil, name: nil)

        let result2 = await ClassificationManager.shared.classifyDevice(model: model, vendor: vendor, appearance: nil, hardware: nil, name: nil)

        XCTAssertEqual(result1.category, result2.category)
        XCTAssertEqual(result1.confidence, result2.confidence)
        XCTAssertEqual(result1.summary, result2.summary)
    }

    func testEmptyModelHandling() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "", vendor: nil, appearance: nil, hardware: nil, name: nil)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.category, .unknown)
    }

    func testConfidenceScoreRange() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "MagicMouse", vendor: "Apple", appearance: nil, hardware: nil, name: nil)

        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
    }

    func testSummaryNotEmpty() async throws {
        let result = await ClassificationManager.shared.classifyDevice(model: "MagicMouse2,1", vendor: "Apple Inc", appearance: nil, hardware: nil, name: "Magic Mouse")

        XCTAssertFalse(result.summary.isEmpty)
        XCTAssertGreater(result.summary.count, 5)
    }
}
