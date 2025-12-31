//
//  SwiftDataIntegrationTests.swift
//  BatteryBoiTests
//
//  Created by Claude on 12/30/25.
//

import XCTest
import SwiftData
@testable import BatteryBoi

final class SwiftDataIntegrationTests: XCTestCase {

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

    func testModelContainerCreation() throws {
        XCTAssertNotNil(testContainer, "ModelContainer should be created")
        XCTAssertNotNil(testContext, "ModelContext should be created")
    }

    func testCloudManagerContainerConfiguration() throws {
        XCTAssertNotNil(CloudManager.container, "CloudManager should have a container")
        XCTAssertNotNil(CloudManager.container?.container, "CloudManager container should have ModelContainer")
    }

    func testDevicesObjectCRUD() throws {
        let device = DevicesObject()
        device.id = UUID()
        device.name = "Test Device"
        device.model = "MacBook Pro"
        device.type = "Computer"
        device.favourite = true
        device.notifications = true

        testContext.insert(device)
        try testContext.save()

        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == device.id })
        let fetchedDevices = try testContext.fetch(descriptor)

        XCTAssertEqual(fetchedDevices.count, 1, "Should fetch exactly one device")
        XCTAssertEqual(fetchedDevices.first?.name, "Test Device")
        XCTAssertEqual(fetchedDevices.first?.model, "MacBook Pro")
        XCTAssertEqual(fetchedDevices.first?.favourite, true)

        fetchedDevices.first?.name = "Updated Device"
        try testContext.save()

        let updatedDevices = try testContext.fetch(descriptor)
        XCTAssertEqual(updatedDevices.first?.name, "Updated Device")

        testContext.delete(device)
        try testContext.save()

        let deletedDevices = try testContext.fetch(descriptor)
        XCTAssertEqual(deletedDevices.count, 0, "Device should be deleted")
    }

    func testBatteryObjectCRUD() throws {
        let battery = BatteryObject()
        battery.id = UUID()
        battery.created = Date()
        battery.percent = 85
        battery.state = "charging"
        battery.mode = "normal"
        battery.cycles = 42
        battery.temprature = 75

        testContext.insert(battery)
        try testContext.save()

        let descriptor = FetchDescriptor<BatteryObject>(predicate: #Predicate { $0.id == battery.id })
        let fetchedBatteries = try testContext.fetch(descriptor)

        XCTAssertEqual(fetchedBatteries.count, 1)
        XCTAssertEqual(fetchedBatteries.first?.percent, 85)
        XCTAssertEqual(fetchedBatteries.first?.state, "charging")
        XCTAssertEqual(fetchedBatteries.first?.cycles, 42)
    }

    func testAlertsObjectCRUD() throws {
        let alert = AlertsObject()
        alert.id = UUID()
        alert.type = "deviceDepleting"
        alert.owner = UUID()
        alert.triggeredOn = Date()
        alert.local = true

        testContext.insert(alert)
        try testContext.save()

        let descriptor = FetchDescriptor<AlertsObject>(predicate: #Predicate { $0.id == alert.id })
        let fetchedAlerts = try testContext.fetch(descriptor)

        XCTAssertEqual(fetchedAlerts.count, 1)
        XCTAssertEqual(fetchedAlerts.first?.type, "deviceDepleting")
        XCTAssertEqual(fetchedAlerts.first?.local, true)
    }

    func testPushObjectCRUD() throws {
        let push = PushObject()
        push.id = UUID()
        push.type = "deviceDepleting"
        push.percent = 15
        push.custom = true
        push.addedOn = Date()

        testContext.insert(push)
        try testContext.save()

        let descriptor = FetchDescriptor<PushObject>(predicate: #Predicate { $0.id == push.id })
        let fetchedPush = try testContext.fetch(descriptor)

        XCTAssertEqual(fetchedPush.count, 1)
        XCTAssertEqual(fetchedPush.first?.type, "deviceDepleting")
        XCTAssertEqual(fetchedPush.first?.percent, 15)
        XCTAssertEqual(fetchedPush.first?.custom, true)
    }

    func testBatteryEntryObjectCRUD() throws {
        let entry = BatteryEntryObject(percentage: 75, isCharging: true, mode: "normal")

        testContext.insert(entry)
        try testContext.save()

        let descriptor = FetchDescriptor<BatteryEntryObject>(predicate: #Predicate { $0.id == entry.id })
        let fetchedEntries = try testContext.fetch(descriptor)

        XCTAssertEqual(fetchedEntries.count, 1)
        XCTAssertEqual(fetchedEntries.first?.percentage, 75)
        XCTAssertEqual(fetchedEntries.first?.charging, true)
        XCTAssertEqual(fetchedEntries.first?.mode, "normal")
    }

    func testDeviceBatteryRelationship() throws {
        let device = DevicesObject()
        device.id = UUID()
        device.name = "Test Device"
        device.model = "iPhone"

        let battery1 = BatteryObject()
        battery1.id = UUID()
        battery1.percent = 80
        battery1.device = device

        let battery2 = BatteryObject()
        battery2.id = UUID()
        battery2.percent = 75
        battery2.device = device

        testContext.insert(device)
        testContext.insert(battery1)
        testContext.insert(battery2)
        try testContext.save()

        let deviceDescriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == device.id })
        let fetchedDevices = try testContext.fetch(deviceDescriptor)

        XCTAssertEqual(fetchedDevices.first?.events?.count, 2, "Device should have 2 battery events")
        XCTAssertTrue(fetchedDevices.first?.events?.contains(where: { $0.percent == 80 }) ?? false)
        XCTAssertTrue(fetchedDevices.first?.events?.contains(where: { $0.percent == 75 }) ?? false)
    }

    func testBatteryAlertRelationship() throws {
        let battery = BatteryObject()
        battery.id = UUID()
        battery.percent = 15

        let alert = AlertsObject()
        alert.id = UUID()
        alert.type = "deviceDepleting"
        alert.event = battery

        testContext.insert(battery)
        testContext.insert(alert)
        try testContext.save()

        let alertDescriptor = FetchDescriptor<AlertsObject>(predicate: #Predicate { $0.id == alert.id })
        let fetchedAlerts = try testContext.fetch(alertDescriptor)

        XCTAssertNotNil(fetchedAlerts.first?.event, "Alert should have associated battery event")
        XCTAssertEqual(fetchedAlerts.first?.event?.percent, 15)
    }

    func testFetchWithSorting() throws {
        for i in 1...5 {
            let battery = BatteryObject()
            battery.id = UUID()
            battery.percent = i * 10
            battery.created = Date().addingTimeInterval(TimeInterval(i * 60))
            testContext.insert(battery)
        }
        try testContext.save()

        var descriptor = FetchDescriptor<BatteryObject>()
        descriptor.sortBy = [SortDescriptor(\.created, order: .reverse)]

        let sorted = try testContext.fetch(descriptor)

        XCTAssertEqual(sorted.count, 5)
        XCTAssertEqual(sorted.first?.percent, 50, "Most recent should be 50%")
        XCTAssertEqual(sorted.last?.percent, 10, "Oldest should be 10%")
    }

    func testFetchWithLimit() throws {
        for i in 1...10 {
            let device = DevicesObject()
            device.id = UUID()
            device.name = "Device \(i)"
            testContext.insert(device)
        }
        try testContext.save()

        var descriptor = FetchDescriptor<DevicesObject>()
        descriptor.fetchLimit = 3

        let limited = try testContext.fetch(descriptor)

        XCTAssertEqual(limited.count, 3, "Should fetch only 3 devices")
    }

    func testFetchWithComplexPredicate() throws {
        let device1 = DevicesObject()
        device1.id = UUID()
        device1.name = "MacBook Pro"
        device1.favourite = true
        device1.hidden = false

        let device2 = DevicesObject()
        device2.id = UUID()
        device2.name = "iPhone"
        device2.favourite = false
        device2.hidden = false

        let device3 = DevicesObject()
        device3.id = UUID()
        device3.name = "iPad"
        device3.favourite = true
        device3.hidden = true

        testContext.insert(device1)
        testContext.insert(device2)
        testContext.insert(device3)
        try testContext.save()

        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.favourite == true && $0.hidden == false })
        let filtered = try testContext.fetch(descriptor)

        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "MacBook Pro")
    }

    func testBulkDelete() throws {
        for i in 1...10 {
            let battery = BatteryObject()
            battery.id = UUID()
            battery.created = Date().addingTimeInterval(TimeInterval(-i * 24 * 60 * 60))
            battery.percent = i * 10
            testContext.insert(battery)
        }
        try testContext.save()

        let oldDate = Date().addingTimeInterval(-5 * 24 * 60 * 60)
        let descriptor = FetchDescriptor<BatteryObject>(predicate: #Predicate { $0.created ?? Date.distantPast < oldDate })
        let oldBatteries = try testContext.fetch(descriptor)

        XCTAssertGreaterThan(oldBatteries.count, 0, "Should have old batteries")

        for battery in oldBatteries {
            testContext.delete(battery)
        }
        try testContext.save()

        let allDescriptor = FetchDescriptor<BatteryObject>()
        let remaining = try testContext.fetch(allDescriptor)

        XCTAssertLessThan(remaining.count, 10, "Should have deleted some batteries")
    }

    func testConcurrentWrites() throws {
        let expectation = XCTestExpectation(description: "Concurrent writes complete")
        expectation.expectedFulfillmentCount = 10

        for i in 1...10 {
            DispatchQueue.global().async {
                let context = ModelContext(self.testContainer)
                let device = DevicesObject()
                device.id = UUID()
                device.name = "Device \(i)"

                context.insert(device)
                try? context.save()

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)

        let descriptor = FetchDescriptor<DevicesObject>()
        let devices = try testContext.fetch(descriptor)

        XCTAssertEqual(devices.count, 10, "All concurrent writes should succeed")
    }

    func testSystemDeviceObjectCreation() throws {
        let device = DevicesObject()
        device.id = UUID()
        device.name = "Test Mac"
        device.model = "MacBookPro18,1"
        device.primary = true
        device.favourite = false

        testContext.insert(device)
        try testContext.save()

        let systemDevice = SystemDeviceObject(device)

        XCTAssertNotNil(systemDevice, "Should create SystemDeviceObject from DevicesObject")
        XCTAssertEqual(systemDevice?.name, "Test Mac")
        XCTAssertEqual(systemDevice?.profile.model, "MacBookPro18,1")
        XCTAssertEqual(systemDevice?.connectivity, .system)
    }

    func testSystemEventObjectCreation() throws {
        let battery = BatteryObject()
        battery.id = UUID()
        battery.created = Date()
        battery.percent = 85
        battery.state = "charging"
        battery.temprature = 75

        testContext.insert(battery)
        try testContext.save()

        let event = SystemEventObject(battery)

        XCTAssertNotNil(event, "Should create SystemEventObject from BatteryObject")
        XCTAssertEqual(event?.percentage, 85)
        XCTAssertEqual(event?.state.rawValue, "charging")
        XCTAssertNotNil(event?.thermal)
        XCTAssertEqual(event?.thermal?.value, 75.0)
    }

    func testSystemPushObjectCreation() throws {
        let push = PushObject()
        push.id = UUID()
        push.type = "deviceDepleting"
        push.percent = 25

        testContext.insert(push)
        try testContext.save()

        let systemPush = SystemPushObject(push)

        XCTAssertNotNil(systemPush, "Should create SystemPushObject from PushObject")
        XCTAssertEqual(systemPush?.type, .deviceDepleting)
        XCTAssertEqual(systemPush?.percentage, 25)
    }

    func testAppStorageContextCreation() throws {
        if let context = AppManager.shared.appStorageContext() {
            XCTAssertNotNil(context, "AppManager should provide a ModelContext")
            XCTAssertTrue(context.autosaveEnabled, "Context should have autosave enabled")
        }
        else {
            XCTFail("AppManager should provide a storage context")
        }
    }

    func testModelRelationshipCascadeDelete() throws {
        let device = DevicesObject()
        device.id = UUID()
        device.name = "Test Device"

        let battery1 = BatteryObject()
        battery1.id = UUID()
        battery1.percent = 80
        battery1.device = device

        let battery2 = BatteryObject()
        battery2.id = UUID()
        battery2.percent = 75
        battery2.device = device

        testContext.insert(device)
        testContext.insert(battery1)
        testContext.insert(battery2)
        try testContext.save()

        testContext.delete(device)
        try testContext.save()

        let batteryDescriptor = FetchDescriptor<BatteryObject>()
        let remainingBatteries = try testContext.fetch(batteryDescriptor)

        XCTAssertEqual(remainingBatteries.count, 0, "Related batteries should be cascade deleted")
    }

    func testOptionalFieldsHandling() throws {
        let device = DevicesObject()
        device.id = UUID()
        device.name = "Minimal Device"

        testContext.insert(device)
        try testContext.save()

        XCTAssertNil(device.serial)
        XCTAssertNil(device.vendor)
        XCTAssertNil(device.address)
        XCTAssertNotNil(device.id)
        XCTAssertNotNil(device.name)
    }

    func testDateHandling() throws {
        let now = Date()
        let device = DevicesObject()
        device.id = UUID()
        device.name = "Test"
        device.addedOn = now
        device.refreshedOn = now

        testContext.insert(device)
        try testContext.save()

        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == device.id })
        let fetched = try testContext.fetch(descriptor)

        XCTAssertNotNil(fetched.first?.addedOn)
        XCTAssertNotNil(fetched.first?.refreshedOn)

        let timeDiff = abs((fetched.first?.addedOn ?? Date()).timeIntervalSince(now))
        XCTAssertLessThan(timeDiff, 1.0, "Dates should be preserved accurately")
    }
}
