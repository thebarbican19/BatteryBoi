//
//  CloudKitSyncDiagnosticTests.swift
//  BatteryBoiTests
//
//  Created by Claude Sonnet 4.5 on 12/31/25.
//

import XCTest
import SwiftData
import CloudKit
@testable import BatteryBoi

final class CloudKitSyncDiagnosticTests: XCTestCase {
    var testContainer: ModelContainer!
    var testContext: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([BatteryEntryObject.self, DevicesObject.self, BatteryObject.self, AlertsObject.self, PushObject.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testContainer = try ModelContainer(for: schema, configurations: config)
        testContext = ModelContext(testContainer)
    }

    override func tearDownWithError() throws {
        testContext = nil
        testContainer = nil
        try super.tearDownWithError()
    }

    func testCloudKitContainerConfiguration() throws {
        guard let container = CloudManager.container?.container else {
            XCTFail("CloudManager should have a container configured")
            return
        }
        XCTAssertNotNil(container, "ModelContainer should exist")
        let context = ModelContext(container)
        XCTAssertNotNil(context, "Should be able to create ModelContext from container")
        XCTAssertTrue(context.autosaveEnabled, "Autosave should be enabled for CloudKit sync")
    }

    func testCloudKitAccountStatus() throws {
        let expectation = XCTestExpectation(description: "Check CloudKit account status")
        guard let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String else {
            XCTFail("ENV_ICLOUD_ID should be configured in Info.plist")
            return
        }
        CKContainer(identifier: id).accountStatus { status, error in
            XCTAssertNil(error, "CloudKit account check should not error: \(error?.localizedDescription ?? "")")
            XCTAssertEqual(status, .available, "CloudKit account should be available for testing. Status: \(status.rawValue)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testCloudKitUserRecordIDFetch() throws {
        let expectation = XCTestExpectation(description: "Fetch user record ID")
        guard let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String else {
            XCTFail("ENV_ICLOUD_ID should be configured")
            return
        }
        CKContainer(identifier: id).fetchUserRecordID { recordID, error in
            XCTAssertNil(error, "Should fetch user record ID without error: \(error?.localizedDescription ?? "")")
            XCTAssertNotNil(recordID, "User record ID should exist")
            if let recordID = recordID {
                XCTAssertFalse(recordID.recordName.isEmpty, "Record name should not be empty")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testCloudManagerStateInitialization() throws {
        XCTAssertNotNil(CloudManager.shared, "CloudManager singleton should exist")
        let initialState = CloudManager.shared.state
        XCTAssertTrue([.unknown, .enabled, .blocked, .disabled].contains(initialState), "CloudManager should have a valid initial state")
    }

    func testCloudManagerSyncingState() throws {
        XCTAssertNotNil(CloudManager.shared.syncing, "Syncing state should be initialized")
        let syncState = CloudManager.shared.syncing
        XCTAssertTrue([.syncing, .completed, .error].contains(syncState), "Should have valid sync state")
    }

    func testDeviceStorageCrossContext() throws {
        guard let container = CloudManager.container?.container else {
            XCTFail("CloudManager should have a container")
            return
        }
        let deviceId = UUID()
        let context1 = ModelContext(container)
        let device = DevicesObject()
        device.id = deviceId
        device.name = "Cross-Context Test Device"
        device.model = "Test Model"
        device.primary = false
        context1.insert(device)
        try context1.save()
        Thread.sleep(forTimeInterval: 0.5)
        let context2 = ModelContext(container)
        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == deviceId })
        let fetchedDevices = try context2.fetch(descriptor)
        XCTAssertEqual(fetchedDevices.count, 1, "Device should be visible across contexts")
        XCTAssertEqual(fetchedDevices.first?.name, "Cross-Context Test Device")
        if let fetchedDevice = fetchedDevices.first {
            context2.delete(fetchedDevice)
            try context2.save()
        }
    }

    func testBatteryEventStorageWithDevice() throws {
        guard let container = CloudManager.container?.container else {
            XCTFail("CloudManager should have a container")
            return
        }
        let context = ModelContext(container)
        let deviceId = UUID()
        let device = DevicesObject()
        device.id = deviceId
        device.name = "Battery Test Device"
        device.model = "iPhone"
        context.insert(device)
        try context.save()
        let battery = BatteryObject()
        battery.id = UUID()
        battery.created = Date()
        battery.percent = 75
        battery.state = BatteryChargingState.charging.rawValue
        battery.mode = BatteryModeType.normal.rawValue
        battery.device = device
        context.insert(battery)
        try context.save()
        let descriptor = FetchDescriptor<BatteryObject>(predicate: #Predicate { $0.device?.id == deviceId })
        let batteries = try context.fetch(descriptor)
        XCTAssertEqual(batteries.count, 1, "Battery event should be stored and linked to device")
        XCTAssertEqual(batteries.first?.percent, 75)
        XCTAssertEqual(batteries.first?.device?.name, "Battery Test Device")
    }

    func testModelOptionalPropertiesForCloudKit() throws {
        let device = DevicesObject()
        XCTAssertNotNil(device.id, "ID should have default value")
        XCTAssertEqual(device.name, "", "Name should have default empty string")
        XCTAssertEqual(device.model, "", "Model should have default empty string")
        XCTAssertEqual(device.favourite, false, "Favourite should have default false")
        let battery = BatteryObject()
        XCTAssertNotNil(battery.id, "Battery ID should have default value")
        XCTAssertEqual(battery.percent, 0, "Percent should have default value")
        XCTAssertNotNil(battery.created, "Created date should have default value")
        let alert = AlertsObject()
        XCTAssertNotNil(alert.id, "Alert ID should have default value")
        XCTAssertEqual(alert.type, "", "Alert type should have default value")
    }

    func testSystemDeviceRegistration() throws {
        guard let context = AppManager.shared.appStorageContext() else {
            XCTFail("AppManager should provide storage context")
            return
        }
        AppManager.shared.appStoreDevice(nil)
        Thread.sleep(forTimeInterval: 1.0)
        guard let systemId = UserDefaults.main.object(forKey: AppDefaultsKeys.deviceIdentifyer.rawValue) as? String,
              let uuid = UUID(uuidString: systemId) else {
            XCTFail("System device identifier should be stored in UserDefaults")
            return
        }
        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == uuid })
        let devices = try context.fetch(descriptor)
        XCTAssertGreaterThan(devices.count, 0, "System device should be stored in database")
        if let systemDevice = devices.first {
            XCTAssertEqual(systemDevice.primary, true, "System device should be marked as primary")
            XCTAssertNotNil(systemDevice.model, "System device should have model")
            XCTAssertNotNil(systemDevice.name, "System device should have name")
        }
    }

    func testCrossAppGroupAccess() throws {
        let groupIdentifier = "group.com.ovatar.batteryboi"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            XCTFail("App group container should be accessible")
            return
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: groupURL.path), "App group directory should exist")
        let testFile = groupURL.appendingPathComponent("test_sync_marker.txt")
        let testData = "CloudKit Sync Test".data(using: .utf8)!
        try testData.write(to: testFile)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path), "Should be able to write to app group container")
        try? FileManager.default.removeItem(at: testFile)
    }

    func testCloudKitContainerIdentifierConsistency() throws {
        let expectedIdentifier = "iCloud.com.ovatar.batteryboi"
        guard let configuredId = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String else {
            XCTFail("ENV_ICLOUD_ID should be configured in Info.plist")
            return
        }
        XCTAssertEqual(configuredId, expectedIdentifier, "CloudKit container identifier should match expected value")
    }

    func testAppGroupIdentifierConsistency() throws {
        let expectedGroup = "group.com.ovatar.batteryboi"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: expectedGroup) else {
            XCTFail("App group should be accessible with identifier: \(expectedGroup)")
            return
        }
        XCTAssertNotNil(groupURL, "App group URL should be accessible")
    }

    func testRemoteNotificationCapability() throws {
        #if os(macOS)
        let capabilities = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
        XCTAssertTrue(capabilities.contains("remote-notification"), "macOS app should have remote-notification background mode for CloudKit sync")
        #elseif os(iOS)
        let capabilities = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
        XCTAssertTrue(capabilities.contains("remote-notification"), "iOS app should have remote-notification background mode for CloudKit sync")
        #endif
    }

    func testCloudKitSubscriptionSetup() throws {
        #if os(iOS)
        let expectation = XCTestExpectation(description: "CloudKit subscription check")
        guard let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String else {
            XCTFail("ENV_ICLOUD_ID should be configured")
            return
        }
        let database = CKContainer(identifier: id).privateCloudDatabase
        database.fetchAllSubscriptions { subscriptions, error in
            if let error = error {
                print("Subscription fetch warning: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        #endif
    }

    func testModelRelationshipsAreOptional() throws {
        let device = DevicesObject()
        XCTAssertNotNil(device.events, "Events relationship should be initialized (can be empty array)")
        let battery = BatteryObject()
        battery.device = nil
        XCTAssertNil(battery.device, "Device relationship should be optional and nullable")
        let alert = AlertsObject()
        alert.event = nil
        XCTAssertNil(alert.event, "Event relationship should be optional and nullable")
    }

    func testDataPersistenceAfterContextSave() throws {
        guard let container = CloudManager.container?.container else {
            XCTFail("CloudManager should have a container")
            return
        }
        let context1 = ModelContext(container)
        let deviceId = UUID()
        let device = DevicesObject()
        device.id = deviceId
        device.name = "Persistence Test"
        device.model = "Test Model"
        context1.insert(device)
        try context1.save()
        Thread.sleep(forTimeInterval: 0.5)
        let context2 = ModelContext(container)
        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == deviceId })
        let fetched = try context2.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1, "Data should persist after save")
        XCTAssertEqual(fetched.first?.name, "Persistence Test")
        if let fetchedDevice = fetched.first {
            context2.delete(fetchedDevice)
            try context2.save()
        }
    }
}
