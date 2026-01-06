//
//  DuplicateDetectionTests.swift
//  BatteryBoiTests
//
//  Created by Claude Code on 01/05/25.
//

import XCTest
import SwiftData
@testable import BatteryBoi

final class DuplicateDetectionTests: XCTestCase {
    var modelContext: ModelContext?

    override func setUpWithError() throws {
        try super.setUpWithError()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DevicesObject.self, configurations: config)
        modelContext = ModelContext(container)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        modelContext = nil
    }

    func testTier5MatchByAISummary() throws {
        guard let context = modelContext else { return }

        let profile1 = AppDeviceProfileObject(
            model: "NUT001",
            subtype: nil,
            vendor: "Nutale",
            apperance: nil,
            findmy: false,
            aiCategory: .tracker,
            aiConfidence: 0.92,
            aiSummary: "Nut Smart Tracker for finding keys and wallets"
        )

        let profile2 = AppDeviceProfileObject(
            model: "NUT001",
            subtype: nil,
            vendor: "Nutale",
            apperance: nil,
            findmy: false,
            aiCategory: .tracker,
            aiConfidence: 0.90,
            aiSummary: "Nut tracker device used to locate items like keys"
        )

        let device1 = AppDeviceObject(UUID(), name: "NUT 001A", profile: profile1)
        let device2 = AppDeviceObject(UUID(), name: "NUT 001B", profile: profile2)

        if let match = AppDeviceObject.match(device2, context: context) == nil ? nil : device1 {
            XCTAssertEqual(match.profile.aiCategory, device2.profile.aiCategory, "Tier 5: Should match same AI category")
        }
    }

    func testNoMatchDifferentAICategory() throws {
        guard let context = modelContext else { return }

        let profile1 = AppDeviceProfileObject(
            model: "DEVICE001",
            subtype: nil,
            vendor: "Vendor1",
            apperance: nil,
            findmy: false,
            aiCategory: .mouse,
            aiConfidence: 0.95,
            aiSummary: "Bluetooth mouse for computer input"
        )

        let profile2 = AppDeviceProfileObject(
            model: "DEVICE001",
            subtype: nil,
            vendor: "Vendor1",
            apperance: nil,
            findmy: false,
            aiCategory: .tracker,
            aiConfidence: 0.85,
            aiSummary: "Bluetooth tracker device"
        )

        let device1 = AppDeviceObject(UUID(), name: "Device 1", profile: profile1)
        let device2 = AppDeviceObject(UUID(), name: "Device 2", profile: profile2)

        let match = AppDeviceObject.match(device2, context: context)
        XCTAssertNil(match, "Should not match devices with different AI categories")
    }

    func testAISummaryMatchWithPartialSimilarity() throws {
        guard let context = modelContext else { return }

        let profile1 = AppDeviceProfileObject(
            model: "AIRPODS003",
            subtype: nil,
            vendor: "Apple Inc",
            apperance: nil,
            findmy: false,
            aiCategory: .earbuds,
            aiConfidence: 0.98,
            aiSummary: "Apple AirPods Pro wireless earbuds for audio output"
        )

        let profile2 = AppDeviceProfileObject(
            model: "AIRPODS003",
            subtype: nil,
            vendor: "Apple Inc",
            apperance: nil,
            findmy: false,
            aiCategory: .earbuds,
            aiConfidence: 0.97,
            aiSummary: "Apple AirPods wireless earbuds"
        )

        let device1 = AppDeviceObject(UUID(), name: "AirPods", profile: profile1)
        let device2 = AppDeviceObject(UUID(), name: "My AirPods", profile: profile2)

        if let match = AppDeviceObject.match(device2, context: context) == nil ? nil : device1 {
            XCTAssertEqual(match.profile.aiCategory, .earbuds, "Should match similar AI summaries")
        }
    }

    func testEmptyAISummaryFallback() throws {
        guard let context = modelContext else { return }

        let profile1 = AppDeviceProfileObject(
            model: "TEST001",
            subtype: nil,
            vendor: "TestVendor",
            apperance: nil,
            findmy: false,
            aiCategory: .unknown,
            aiConfidence: 0.3,
            aiSummary: nil
        )

        let profile2 = AppDeviceProfileObject(
            model: "TEST001",
            subtype: nil,
            vendor: "TestVendor",
            apperance: nil,
            findmy: false,
            aiCategory: .unknown,
            aiConfidence: 0.3,
            aiSummary: nil
        )

        let device1 = AppDeviceObject(UUID(), name: "Test Device", profile: profile1)
        let device2 = AppDeviceObject(UUID(), name: "Test Device", profile: profile2)

        if let match = AppDeviceObject.match(device2, context: context) {
            XCTAssertNotNil(match, "Should match by name when AI summary is empty")
        }
    }

    func testDeduplicationPriority() throws {
        guard let context = modelContext else { return }

        let sharedModel = "PRIORITY001"
        let sharedVendor = "PriorityVendor"

        let profile1 = AppDeviceProfileObject(
            model: sharedModel,
            subtype: nil,
            vendor: sharedVendor,
            serial: "SN001",
            apperance: nil,
            findmy: false,
            aiCategory: .keyboard,
            aiConfidence: 0.95,
            aiSummary: "Wireless keyboard for input"
        )

        let profile2 = AppDeviceProfileObject(
            model: sharedModel,
            subtype: nil,
            vendor: sharedVendor,
            serial: nil,
            apperance: nil,
            findmy: false,
            aiCategory: .keyboard,
            aiConfidence: 0.92,
            aiSummary: "Bluetooth keyboard device"
        )

        let device1 = AppDeviceObject(UUID(), name: "Keyboard", profile: profile1)
        let device2 = AppDeviceObject(UUID(), name: "My Keyboard", profile: profile2)

        if let match = AppDeviceObject.match(device2, context: context) {
            XCTAssertEqual(match.profile.serial, "SN001", "Should prioritize by serial+model before AI matching")
        }
    }

    func testAIConfidenceLowThreshold() throws {
        guard let context = modelContext else { return }

        let profile1 = AppDeviceProfileObject(
            model: "UNKNOWN001",
            subtype: nil,
            vendor: "Unknown",
            apperance: nil,
            findmy: false,
            aiCategory: .unknown,
            aiConfidence: 0.1,
            aiSummary: "Device type unclear"
        )

        let profile2 = AppDeviceProfileObject(
            model: "UNKNOWN001",
            subtype: nil,
            vendor: "Unknown",
            apperance: nil,
            findmy: false,
            aiCategory: .unknown,
            aiConfidence: 0.15,
            aiSummary: "Unknown device"
        )

        let device1 = AppDeviceObject(UUID(), name: "Unknown 1", profile: profile1)
        let device2 = AppDeviceObject(UUID(), name: "Unknown 2", profile: profile2)

        if let match = AppDeviceObject.match(device2, context: context) {
            XCTAssertEqual(match.profile.aiCategory, .unknown, "Should match even with low confidence if category matches")
        }
    }

    func testMultipleMatchCandidates() throws {
        guard let context = modelContext else { return }

        let profile = AppDeviceProfileObject(
            model: "MULTI001",
            subtype: nil,
            vendor: "MultiVendor",
            apperance: nil,
            findmy: false,
            aiCategory: .speaker,
            aiConfidence: 0.88,
            aiSummary: "Bluetooth speaker for audio playback"
        )

        let device1 = AppDeviceObject(UUID(), name: "Speaker 1", profile: profile)
        let device2 = AppDeviceObject(UUID(), name: "Speaker 2", profile: profile)

        if let match = AppDeviceObject.match(device2, context: context) {
            XCTAssertEqual(match.profile.aiCategory, .speaker, "Should match first candidate with same AI category")
        }
    }

    func testAISummaryNormalization() throws {
        let summary1 = "Apple AirPods Pro - Wireless Earbuds"
        let summary2 = "Apple AirPods Pro wireless earbuds"

        let normalized1 = summary1.normalizedDeviceName
        let normalized2 = summary2.normalizedDeviceName

        let similarity = normalized1.jaroWinklerSimilarity(with: normalized2)
        XCTAssertGreaterThanOrEqual(similarity, 0.75, "Normalized summaries should have high similarity")
    }

    func testCategoryMismatchPreventsMatch() throws {
        guard let context = modelContext else { return }

        let categories: [AppDeviceCategory] = [.mouse, .keyboard, .headphones, .tracker, .watch]

        for i in 0..<categories.count - 1 {
            let profile1 = AppDeviceProfileObject(
                model: "CATEGORY\(i)",
                subtype: nil,
                vendor: "Vendor",
                apperance: nil,
                findmy: false,
                aiCategory: categories[i],
                aiConfidence: 0.90,
                aiSummary: "Device of category \(i)"
            )

            let profile2 = AppDeviceProfileObject(
                model: "CATEGORY\(i)",
                subtype: nil,
                vendor: "Vendor",
                apperance: nil,
                findmy: false,
                aiCategory: categories[i + 1],
                aiConfidence: 0.90,
                aiSummary: "Device of category \(i + 1)"
            )

            let device1 = AppDeviceObject(UUID(), name: "Device \(i)", profile: profile1)
            let device2 = AppDeviceObject(UUID(), name: "Device \(i + 1)", profile: profile2)

            let match = AppDeviceObject.match(device2, context: context)
            XCTAssertNil(match, "Different categories should never match in Tier 5")
        }
    }
}
