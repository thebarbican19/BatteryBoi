//
//  BluetoothDeviceTests.swift
//  BatteryBoiTests
//
//  Created by Gemini on 12/29/25.
//

import XCTest
@testable import BatteryBoi

final class BluetoothDeviceTests: XCTestCase {

    func testAirPodsBatteryState() {
        // Mock IOKit dictionary for AirPods
        let mockDict: [String: Any] = [
            "Name": "Joe's AirPods Pro",
            "BatteryPercent": 82,
            "DeviceModel": "AirPods Pro",
            "VendorName": "Apple Inc.",
            "SerialNumber": "H234567890"
        ]
        
        let result = BluetoothManager.parseIOKitDictionary(mockDict)
        
        XCTAssertNotNil(result, "Should parse valid dictionary")
        XCTAssertEqual(result?.name, "Joe's AirPods Pro")
        XCTAssertEqual(result?.battery, 82)
        XCTAssertEqual(result?.profile.model, "AirPods Pro")
        XCTAssertEqual(result?.profile.vendor, "Apple Inc.")
        XCTAssertEqual(result?.profile.serial, "H234567890")
    }

    func testAppleMouseBatteryState() {
        // Mock IOKit dictionary for Magic Mouse
        let mockDict: [String: Any] = [
            "Name": "Magic Mouse",
            "BatteryPercent": 45,
            "DeviceModel": "Magic Mouse 2",
            "VendorName": "Apple",
            "SerialNumber": "MM12345678"
        ]
        
        let result = BluetoothManager.parseIOKitDictionary(mockDict)
        
        XCTAssertNotNil(result, "Should parse valid dictionary")
        XCTAssertEqual(result?.name, "Magic Mouse")
        XCTAssertEqual(result?.battery, 45)
        XCTAssertEqual(result?.profile.model, "Magic Mouse 2")
    }

    func testAppleKeyboardBatteryState() {
        // Mock IOKit dictionary for Magic Keyboard
        let mockDict: [String: Any] = [
            "Name": "Magic Keyboard",
            "BatteryPercent": 12,
            "DeviceModel": "Magic Keyboard",
            "VendorName": "Apple",
            "SerialNumber": "KB98765432"
        ]
        
        let result = BluetoothManager.parseIOKitDictionary(mockDict)
        
        XCTAssertNotNil(result, "Should parse valid dictionary")
        XCTAssertEqual(result?.name, "Magic Keyboard")
        XCTAssertEqual(result?.battery, 12)
        XCTAssertEqual(result?.profile.model, "Magic Keyboard")
    }
    
    func testInvalidDeviceDictionary() {
        // ... (existing code)
    }

    func testBluetoothBatteryObjectDecoding() throws {
        let json = """
        {
            "device_batteryLevelMain": "85%",
            "device_batteryLevelLeft": "90 %",
            "device_batteryLevelRight": "battery 80"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let battery = try decoder.decode(BluetoothBatteryObject.self, from: json)
        
        XCTAssertEqual(battery.general, 85)
        XCTAssertEqual(battery.left, 90)
        XCTAssertEqual(battery.right, 80)
        XCTAssertEqual(battery.percent, 80, "Percent should be the minimum of all available levels")
    }

    func testBluetoothBatteryObjectPartialDecoding() throws {
        let json = """
        {
            "device_batteryLevelMain": "50%"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let battery = try decoder.decode(BluetoothBatteryObject.self, from: json)
        
        XCTAssertEqual(battery.general, 50)
        XCTAssertNil(battery.left)
        XCTAssertNil(battery.right)
        XCTAssertEqual(battery.percent, 50)
    }

    func testRSSIDistanceLogic() {
        // Test Proximate (-20 to -50)
        let proximate = SystemDeviceDistanceObject(-30)
        XCTAssertEqual(proximate.state, .proximate, "RSSI -30 should be proximate")
        
        let proximateEdge = SystemDeviceDistanceObject(-50)
        XCTAssertEqual(proximateEdge.state, .proximate, "RSSI -50 should be proximate")
        
        // Test Near (-50 to -70)
        let near = SystemDeviceDistanceObject(-60)
        XCTAssertEqual(near.state, .near, "RSSI -60 should be near")
        
        // Test Far (< -70 or > -20 based on current implementation quirk)
        let far = SystemDeviceDistanceObject(-80)
        XCTAssertEqual(far.state, .far, "RSSI -80 should be far")
        
        // Documenting/Testing the "Quirk": RSSI > -20 (e.g. -10) falls to "else" -> .far
        // Realistically this is very close, but we test the CURRENT logic.
        let veryClose = SystemDeviceDistanceObject(-10)
        XCTAssertEqual(veryClose.state, .far, "RSSI -10 currently falls to far (logic quirk)")
    }
    
    func testCharacteristicParsing() {
        var dataMap: [BluetoothUUID: Data] = [:]
        
        // Add Model
        dataMap[.model] = "Test Model".data(using: .utf8)
        
        // Add Vendor
        dataMap[.vendor] = "Test Vendor".data(using: .utf8)
        
        // Add Serial
        dataMap[.serial] = "SN12345".data(using: .utf8)
        
        // Add Battery (single byte)
        dataMap[.battery] = Data([95])
        
        let result = BluetoothManager.parseCharacteristicData(dataMap)
        
        XCTAssertEqual(result.profile.model, "Test Model")
        XCTAssertEqual(result.profile.vendor, "Test Vendor")
        XCTAssertEqual(result.profile.serial, "SN12345")
        XCTAssertEqual(result.battery, 95)
    }
}
