//
//  AlertDeduplicationTests.swift
//  BatteryBoiTests
//
//  Created by Claude on 01/01/26.
//

import XCTest
import SwiftData
@testable import BatteryBoi

final class AlertDeduplicationTests: XCTestCase {

    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var alertManager: AlertManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let schema = Schema([BatteryEntryObject.self, DevicesObject.self, BatteryObject.self, AlertsObject.self, PushObject.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testContainer = try ModelContainer(for: schema, configurations: config)
        testContext = ModelContext(testContainer)
        alertManager = AlertManager()
    }

    override func tearDownWithError() throws {
        alertManager = nil
        testContext = nil
        testContainer = nil
        try super.tearDownWithError()
    }

    func testAlertCreationAddsNewAlert() throws {
        UserDefaults.main.set("12345678-1234-1234-1234-123456789012", forKey: AppDefaultsKeys.deviceIdentifyer.rawValue)

        let batteryEvent = BatteryObject()
        batteryEvent.id = UUID()
        batteryEvent.percent = 15
        batteryEvent.charging = false
        batteryEvent.created = Date()
        testContext.insert(batteryEvent)
        try testContext.save()

        let pushConfig = PushObject()
        pushConfig.id = UUID()
        pushConfig.type = AppAlertTypes.deviceDepleting.rawValue
        pushConfig.percent = 15
        pushConfig.custom = false
        testContext.insert(pushConfig)
        try testContext.save()

        alertManager.alerts = [AppPushObject(pushConfig)].compactMap { $0 }

        let event = AppEventObject(batteryEvent)

        alertManager.alertCreate(event: event, force: nil, context: testContext)

        let descriptor = FetchDescriptor<AlertsObject>()
        let alerts = try testContext.fetch(descriptor)

        XCTAssertEqual(alerts.count, 1, "Should create exactly one alert")
        XCTAssertEqual(alerts.first?.type, AppAlertTypes.deviceDepleting.rawValue, "Alert type should match")
        XCTAssertEqual(alerts.first?.event?.id, batteryEvent.id, "Alert should be linked to battery event")
    }

    func testAlertDeduplicationPreventsDuplicateNotifications() throws {
        UserDefaults.main.set("12345678-1234-1234-1234-123456789012", forKey: AppDefaultsKeys.deviceIdentifyer.rawValue)

        let batteryEvent = BatteryObject()
        batteryEvent.id = UUID()
        batteryEvent.percent = 15
        batteryEvent.charging = false
        batteryEvent.created = Date()
        testContext.insert(batteryEvent)
        try testContext.save()

        let pushConfig = PushObject()
        pushConfig.id = UUID()
        pushConfig.type = AppAlertTypes.deviceDepleting.rawValue
        pushConfig.percent = 15
        pushConfig.custom = false
        testContext.insert(pushConfig)
        try testContext.save()

        alertManager.alerts = [AppPushObject(pushConfig)].compactMap { $0 }

        let event = AppEventObject(batteryEvent)

        alertManager.alertCreate(event: event, force: nil, context: testContext)

        alertManager.alertCreate(event: event, force: nil, context: testContext)

        let descriptor = FetchDescriptor<AlertsObject>()
        let alerts = try testContext.fetch(descriptor)

        XCTAssertEqual(alerts.count, 1, "Should still have only one alert after duplicate creation attempt")
    }

    func testLastTriggeredAlertTracking() throws {
        UserDefaults.main.set("12345678-1234-1234-1234-123456789012", forKey: AppDefaultsKeys.deviceIdentifyer.rawValue)

        let batteryEvent = BatteryObject()
        batteryEvent.id = UUID()
        batteryEvent.percent = 15
        batteryEvent.charging = false
        batteryEvent.created = Date()
        testContext.insert(batteryEvent)
        try testContext.save()

        let pushConfig = PushObject()
        pushConfig.id = UUID()
        pushConfig.type = AppAlertTypes.deviceDepleting.rawValue
        pushConfig.percent = 15
        pushConfig.custom = false
        testContext.insert(pushConfig)
        try testContext.save()

        alertManager.alerts = [AppPushObject(pushConfig)].compactMap { $0 }

        let event = AppEventObject(batteryEvent)

        alertManager.alertCreate(event: event, force: nil, context: testContext)

        XCTAssertNotNil(alertManager.lastTriggeredAlert, "Last triggered alert should be tracked")
        XCTAssertEqual(alertManager.lastTriggeredAlert?.eventId, batteryEvent.id, "Tracked event ID should match")
        XCTAssertEqual(alertManager.lastTriggeredAlert?.type, AppAlertTypes.deviceDepleting.rawValue, "Tracked type should match")
    }

    func testDifferentAlertTypesCanBeCreated() throws {
        UserDefaults.main.set("12345678-1234-1234-1234-123456789012", forKey: AppDefaultsKeys.deviceIdentifyer.rawValue)

        let batteryEvent1 = BatteryObject()
        batteryEvent1.id = UUID()
        batteryEvent1.percent = 15
        batteryEvent1.charging = false
        batteryEvent1.created = Date()
        testContext.insert(batteryEvent1)

        let batteryEvent2 = BatteryObject()
        batteryEvent2.id = UUID()
        batteryEvent2.percent = 100
        batteryEvent2.charging = true
        batteryEvent2.created = Date()
        testContext.insert(batteryEvent2)

        try testContext.save()

        let pushConfig1 = PushObject()
        pushConfig1.id = UUID()
        pushConfig1.type = AppAlertTypes.deviceDepleting.rawValue
        pushConfig1.percent = 15
        pushConfig1.custom = false
        testContext.insert(pushConfig1)

        let pushConfig2 = PushObject()
        pushConfig2.id = UUID()
        pushConfig2.type = AppAlertTypes.chargingComplete.rawValue
        pushConfig2.custom = false
        testContext.insert(pushConfig2)

        try testContext.save()

        alertManager.alerts = [AppPushObject(pushConfig1), AppPushObject(pushConfig2)].compactMap { $0 }

        let event1 = AppEventObject(batteryEvent1)
        let event2 = AppEventObject(batteryEvent2)

        BatteryManager.shared.charging = .charging
        BatteryManager.shared.max = 100

        alertManager.alertCreate(event: event1, force: nil, context: testContext)
        alertManager.alertCreate(event: event2, force: nil, context: testContext)

        let descriptor = FetchDescriptor<AlertsObject>()
        let alerts = try testContext.fetch(descriptor)

        XCTAssertEqual(alerts.count, 2, "Should create two different alerts")

        let types = Set(alerts.compactMap { $0.type })
        XCTAssertTrue(types.contains(AppAlertTypes.deviceDepleting.rawValue), "Should include depleting alert")
        XCTAssertTrue(types.contains(AppAlertTypes.chargingComplete.rawValue), "Should include charging complete alert")
    }

    func testExistingAlertDoesNotTriggerDuplicate() throws {
        UserDefaults.main.set("12345678-1234-1234-1234-123456789012", forKey: AppDefaultsKeys.deviceIdentifyer.rawValue)

        let batteryEvent = BatteryObject()
        batteryEvent.id = UUID()
        batteryEvent.percent = 15
        batteryEvent.charging = false
        batteryEvent.created = Date()
        testContext.insert(batteryEvent)

        let existingAlert = AlertsObject()
        existingAlert.id = UUID()
        existingAlert.event = batteryEvent
        existingAlert.type = AppAlertTypes.deviceDepleting.rawValue
        existingAlert.triggeredOn = Date()
        testContext.insert(existingAlert)

        try testContext.save()

        let pushConfig = PushObject()
        pushConfig.id = UUID()
        pushConfig.type = AppAlertTypes.deviceDepleting.rawValue
        pushConfig.percent = 15
        pushConfig.custom = false
        testContext.insert(pushConfig)
        try testContext.save()

        alertManager.alerts = [AppPushObject(pushConfig)].compactMap { $0 }

        let event = AppEventObject(batteryEvent)

        alertManager.lastTriggeredAlert = (eventId: batteryEvent.id!, type: AppAlertTypes.deviceDepleting.rawValue, triggeredOn: Date())

        alertManager.alertCreate(event: event, force: nil, context: testContext)

        let descriptor = FetchDescriptor<AlertsObject>()
        let alerts = try testContext.fetch(descriptor)

        XCTAssertEqual(alerts.count, 1, "Should still have only one alert")
    }

    func testAlertResetCreatesDefaultPushObjects() throws {
        alertManager.alertReset()

        guard let context = AppManager.shared.appStorageContext() else {
            XCTFail("Should have app storage context")
            return

        }

        let descriptor = FetchDescriptor<PushObject>()
        let pushObjects = try context.fetch(descriptor)

        XCTAssertGreaterThanOrEqual(pushObjects.count, 7, "Should create at least 7 default push configurations")

        let depletingAlerts = pushObjects.filter { $0.type == AppAlertTypes.deviceDepleting.rawValue }
        XCTAssertEqual(depletingAlerts.count, 4, "Should create 4 depleting alerts (1%, 5%, 15%, 25%)")

        let percentages = Set(depletingAlerts.compactMap { $0.percent })
        XCTAssertTrue(percentages.contains(1), "Should include 1% alert")
        XCTAssertTrue(percentages.contains(5), "Should include 5% alert")
        XCTAssertTrue(percentages.contains(15), "Should include 15% alert")
        XCTAssertTrue(percentages.contains(25), "Should include 25% alert")
    }

}
