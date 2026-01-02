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

    func testCrossAppDeviceSynchronization() throws {
        let deviceId = UUID()
        let deviceName = "Cross-App Test Device"

        let context1 = ModelContext(testContainer)
        let device = DevicesObject()
        device.id = deviceId
        device.name = deviceName
        device.model = "MacBook Pro"
        device.type = "Computer"
        device.favourite = true
        device.notifications = true

        context1.insert(device)
        try context1.save()

        let context2 = ModelContext(testContainer)
        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == deviceId })
        let fetchedDevices = try context2.fetch(descriptor)

        XCTAssertEqual(fetchedDevices.count, 1, "Device created in context1 should be visible in context2")
        XCTAssertEqual(fetchedDevices.first?.name, deviceName, "Device name should match")
        XCTAssertEqual(fetchedDevices.first?.favourite, true, "Device properties should be preserved")

        if let fetchedDevice = fetchedDevices.first {
            context2.delete(fetchedDevice)
            try context2.save()
        }

        let verifyDelete = try context1.fetch(descriptor)
        XCTAssertEqual(verifyDelete.count, 0, "Device deleted in context2 should be gone in context1")
    }

    func testCloudManagerSharedContainerSynchronization() throws {
        guard let container = CloudManager.container?.container else {
            XCTFail("CloudManager should have a shared container")
            return
        }

        let deviceId = UUID()
        let appContext1 = ModelContext(container)
        let device = DevicesObject()
        device.id = deviceId
        device.name = "Shared Container Test Device"
        device.model = "iPhone"
        device.type = "Phone"

        appContext1.insert(device)
        try appContext1.save()

        let appContext2 = ModelContext(container)
        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == deviceId })
        let fetchedDevices = try appContext2.fetch(descriptor)

        XCTAssertEqual(fetchedDevices.count, 1, "Device should be visible across contexts using CloudManager's container")
        XCTAssertEqual(fetchedDevices.first?.name, "Shared Container Test Device")

        if let fetchedDevice = fetchedDevices.first {
            appContext2.delete(fetchedDevice)
            try appContext2.save()

            let deletedDevices = try appContext1.fetch(descriptor)
            XCTAssertEqual(deletedDevices.count, 0, "Device deletion should be synchronized across contexts")
        }
    }

    func testBluetoothDeviceStorageIntegration() throws {
        let deviceId = UUID()
        let deviceName = "Magic Mouse"
        let batteryLevel = 85

        let device = DevicesObject()
        device.id = deviceId
        device.name = deviceName
        device.model = "Magic Mouse 2"
        device.vendor = "Apple Inc"
        device.type = "mouse"
        device.subtype = "BluetoothDevice"
        device.notifications = true
        device.favourite = false
        device.primary = false
        device.addedOn = Date()
        device.refreshedOn = Date()

        testContext.insert(device)
        try testContext.save()

        let battery = BatteryObject()
        battery.id = UUID()
        battery.created = Date()
        battery.percent = batteryLevel
        battery.state = "battery"
        battery.mode = "normal"
        battery.device = device

        testContext.insert(battery)
        try testContext.save()

        let deviceDescriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == deviceId })
        let fetchedDevices = try testContext.fetch(deviceDescriptor)

        XCTAssertEqual(fetchedDevices.count, 1, "Bluetooth device should be stored")
        XCTAssertEqual(fetchedDevices.first?.name, deviceName)
        XCTAssertEqual(fetchedDevices.first?.model, "Magic Mouse 2")
        XCTAssertEqual(fetchedDevices.first?.vendor, "Apple Inc")
        XCTAssertEqual(fetchedDevices.first?.events?.count, 1, "Device should have battery event")
        XCTAssertEqual(fetchedDevices.first?.events?.first?.percent, batteryLevel)

        let batteryDescriptor = FetchDescriptor<BatteryObject>(predicate: #Predicate { $0.device?.id == deviceId })
        let fetchedBatteries = try testContext.fetch(batteryDescriptor)

        XCTAssertEqual(fetchedBatteries.count, 1, "Battery event should be linked to device")
        XCTAssertEqual(fetchedBatteries.first?.device?.name, deviceName)
    }

    func testBluetoothDeviceMatchingBySerial() throws {
        let serialNumber = "ABC123XYZ"
        let model = "Magic Mouse 2"

        let device1 = DevicesObject()
        device1.id = UUID()
        device1.name = "Magic Mouse"
        device1.model = model
        device1.serial = serialNumber
        device1.vendor = "Apple Inc"

        testContext.insert(device1)
        try testContext.save()

        let tempDevice = AppDeviceObject(UUID(), name: "Magic Mouse", profile: AppDeviceProfileObject(model: model, vendor: "Apple Inc", serial: serialNumber, hardware: nil, apperance: nil, findmy: false))

        let match = AppDeviceObject.match(tempDevice, context: testContext)

        XCTAssertNotNil(match, "Should match device by serial number")
        XCTAssertEqual(match?.profile.serial, serialNumber)
        XCTAssertEqual(match?.profile.model, model)
    }

    func testBluetoothDeviceMatchingByName() throws {
        let deviceName = "Magic Mouse"
        let model = "Magic Mouse 2"

        let device1 = DevicesObject()
        device1.id = UUID()
        device1.name = deviceName
        device1.model = model

        testContext.insert(device1)
        try testContext.save()

        let tempDevice = AppDeviceObject(UUID(), name: deviceName, profile: AppDeviceProfileObject(model: model, vendor: nil, serial: nil, hardware: nil, apperance: nil, findmy: false))

        let match = AppDeviceObject.match(tempDevice, context: testContext)

        XCTAssertNotNil(match, "Should match device by name")
        XCTAssertEqual(match?.name, deviceName)
    }

    func testMultipleBatteryEventsForSameDevice() throws {
        let deviceId = UUID()
        let device = DevicesObject()
        device.id = deviceId
        device.name = "Magic Keyboard"
        device.model = "Magic Keyboard"

        testContext.insert(device)
        try testContext.save()

        let batteryLevels = [100, 95, 90, 85, 80]
        for (index, level) in batteryLevels.enumerated() {
            let battery = BatteryObject()
            battery.id = UUID()
            battery.created = Date().addingTimeInterval(TimeInterval(index * 60))
            battery.percent = level
            battery.state = "battery"
            battery.device = device

            testContext.insert(battery)
        }
        try testContext.save()

        let descriptor = FetchDescriptor<BatteryObject>(predicate: #Predicate { $0.device?.id == deviceId })
        let batteries = try testContext.fetch(descriptor)

        XCTAssertEqual(batteries.count, 5, "Should have 5 battery events")

        var sortedDescriptor = descriptor
        sortedDescriptor.sortBy = [SortDescriptor(\.created, order: .reverse)]
        let sortedBatteries = try testContext.fetch(sortedDescriptor)

        XCTAssertEqual(sortedBatteries.first?.percent, 80, "Most recent battery level should be 80%")
        XCTAssertEqual(sortedBatteries.last?.percent, 100, "Oldest battery level should be 100%")
    }

    func testBluetoothDeviceWithAddress() throws {
        let deviceName = "Magic Mouse"
        let bluetoothAddress = "a1:b2:c3:d4:e5:f6"
        let model = "Magic Mouse 2"

        let device = DevicesObject()
        device.id = UUID()
        device.name = deviceName
        device.model = model
        device.address = bluetoothAddress
        device.vendor = "Apple Inc"

        testContext.insert(device)
        try testContext.save()

        let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.address == bluetoothAddress })
        let fetchedDevices = try testContext.fetch(descriptor)

        XCTAssertEqual(fetchedDevices.count, 1, "Should find device by Bluetooth address")
        XCTAssertEqual(fetchedDevices.first?.name, deviceName)
        XCTAssertEqual(fetchedDevices.first?.address, bluetoothAddress)

        let matchDevice = AppDeviceObject(UUID(), name: deviceName, profile: AppDeviceProfileObject(model: model, vendor: "Apple Inc", serial: nil, hardware: nil, apperance: nil, findmy: false))

        let match = AppDeviceObject.match(matchDevice, context: testContext)

        XCTAssertNotNil(match, "Should match device by name even without address in query")
    }

    func testDeviceConnectionDisconnectionEvents() throws {
        let deviceId = UUID()
        let deviceName = "Magic Keyboard"
        let batteryLevel = 95

        let device = DevicesObject()
        device.id = deviceId
        device.name = deviceName
        device.model = "Magic Keyboard"
        device.vendor = "Apple Inc"

        testContext.insert(device)
        try testContext.save()

        let connectBattery = BatteryObject()
        connectBattery.id = UUID()
        connectBattery.created = Date()
        connectBattery.percent = batteryLevel
        connectBattery.state = "battery"
        connectBattery.device = device

        testContext.insert(connectBattery)
        try testContext.save()

        let connectAlert = AlertsObject()
        connectAlert.id = UUID()
        connectAlert.type = "deviceConnected"
        connectAlert.triggeredOn = Date()
        connectAlert.event = connectBattery

        testContext.insert(connectAlert)
        try testContext.save()

        let disconnectBattery = BatteryObject()
        disconnectBattery.id = UUID()
        disconnectBattery.created = Date().addingTimeInterval(3600)
        disconnectBattery.percent = 85
        disconnectBattery.state = "battery"
        disconnectBattery.device = device

        testContext.insert(disconnectBattery)
        try testContext.save()

        let disconnectAlert = AlertsObject()
        disconnectAlert.id = UUID()
        disconnectAlert.type = "deviceDisconnected"
        disconnectAlert.triggeredOn = Date().addingTimeInterval(3600)
        disconnectAlert.event = disconnectBattery

        testContext.insert(disconnectAlert)
        try testContext.save()

        let alertDescriptor = FetchDescriptor<AlertsObject>(predicate: #Predicate { $0.event?.device?.id == deviceId })
        let alerts = try testContext.fetch(alertDescriptor)

        XCTAssertEqual(alerts.count, 2, "Should have connection and disconnection alerts")
        XCTAssertTrue(alerts.contains(where: { $0.type == "deviceConnected" }), "Should have connection alert")
        XCTAssertTrue(alerts.contains(where: { $0.type == "deviceDisconnected" }), "Should have disconnection alert")

        let connectAlertFetched = alerts.first(where: { $0.type == "deviceConnected" })
        XCTAssertNotNil(connectAlertFetched?.event, "Connection alert should have battery event")
        XCTAssertEqual(connectAlertFetched?.event?.percent, batteryLevel)

        let disconnectAlertFetched = alerts.first(where: { $0.type == "deviceDisconnected" })
        XCTAssertNotNil(disconnectAlertFetched?.event, "Disconnection alert should have battery event")
        XCTAssertEqual(disconnectAlertFetched?.event?.device?.name, deviceName)
    }
}
