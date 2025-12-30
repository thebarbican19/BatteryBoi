//
//  SystemIntegrationTests.swift
//  BatteryBoiTests
//
//  Created by Gemini on 12/29/25.
//

import XCTest
@testable import BatteryBoi

final class SystemIntegrationTests: XCTestCase {

    func testCLIResourcesExist() {
        // Verify that the install.sh script exists in the project
        // Note: In a real bundle test, we'd check Bundle.main.url(forResource:...)
        // Here we check the file system relative to the project root for CI/CD consistency.
        
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let scriptPath = currentPath + "/BatteryBoi/Other/Scripts/install.sh"
        
        XCTAssertTrue(fileManager.fileExists(atPath: scriptPath), "install.sh should exist at \(scriptPath)")
    }
    
    func testBluetoothModuleReturnsItemsFromContinuityData() {
        // 0x4C00 is Apple ID (Little Endian: 00 4C)
        // Type 0x07 is Proximity Pairing / Battery Status
        // Length 25 (0x19)
        // Data format usually: [CompanyID_LE, Type, Length, ... BatteryL, BatteryR, BatteryCase ...]
        // Indices in logic:
        // offset + 13 = Left
        // offset + 14 = Right
        // offset + 15 = Case
        
        // Construct a valid payload:
        // Header: 4C 00
        // Type: 07
        // Length: 19 (25 bytes following)
        // Padding: 13 bytes
        // Left: 50 (0x32)
        // Right: 45 (0x2D)
        // Case: 80 (0x50)
        // ... rest
        
        var payload = Data([0x4C, 0x00, 0x07, 0x19])
        payload.append(Data(repeating: 0x00, count: 11)) // Padding 0-10 (11 bytes to reach index 15)
        payload.append(Data([0x32, 0x2D, 0x50])) // 15, 16, 17 (L, R, Case) -> 50, 45, 80
        payload.append(Data(repeating: 0x00, count: 11)) // Remaining padding (need total length >= 29)
        
        let batteryLevel = BluetoothManager.parseContinuityManufacturerData(payload)
        
        XCTAssertNotNil(batteryLevel, "Should parse valid continuity data")
        // Logic takes min() of valid batteries (>0 <=100)
        // Min(50, 45, 80) = 45
        XCTAssertEqual(batteryLevel, 45, "Should return minimum battery level (45)")
    }
    
    func testBluetoothModuleReturnsNilForInvalidData() {
        // Invalid Company ID
        let invalidCompany = Data([0xFF, 0xFF, 0x07, 0x19] + [UInt8](repeating: 0, count: 30))
        XCTAssertNil(BluetoothManager.parseContinuityManufacturerData(invalidCompany))
        
        // Short Data
        let shortData = Data([0x4C, 0x00, 0x07])
        XCTAssertNil(BluetoothManager.parseContinuityManufacturerData(shortData))
    }
}
