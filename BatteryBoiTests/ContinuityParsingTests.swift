//
//  ContinuityParsingTests.swift
//  BatteryBoiTests
//
//  Created by Claude Sonnet 4.5 on 12/31/25.
//

import XCTest
@testable import BatteryBoi

final class ContinuityParsingTests: XCTestCase {

    func testContinuityType07AirPods() {
        var payload = Data([0x4C, 0x00, 0x07, 0x19])
        payload.append(Data(repeating: 0x00, count: 11))
        payload.append(Data([0x32, 0x2D, 0x50]))
        payload.append(Data(repeating: 0x00, count: 11))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.messageType, 0x07)
        XCTAssertEqual(result?.batteryLevel, 45)
        XCTAssertNotNil(result?.batteryComponents)
        XCTAssertEqual(result?.batteryComponents?.left, 50)
        XCTAssertEqual(result?.batteryComponents?.right, 45)
        XCTAssertEqual(result?.batteryComponents?.enclosure, 80)
        XCTAssertEqual(result?.deviceInfo?.deviceType, "AirPods/Accessory")
    }

    func testContinuityType07WithInvalidBatteries() {
        var payload = Data([0x4C, 0x00, 0x07, 0x19])
        payload.append(Data(repeating: 0x00, count: 11))
        payload.append(Data([0x00, 0x65, 0x00]))
        payload.append(Data(repeating: 0x00, count: 11))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.messageType, 0x07)
        XCTAssertEqual(result?.batteryLevel, 101)
        XCTAssertNotNil(result?.batteryComponents)
        XCTAssertNil(result?.batteryComponents?.left)
        XCTAssertEqual(result?.batteryComponents?.right, 101)
        XCTAssertNil(result?.batteryComponents?.enclosure)
    }

    func testContinuityType0CTetheringSource() {
        var payload = Data([0x4C, 0x00, 0x0C, 0x08])
        payload.append(Data(repeating: 0x00, count: 5))
        payload.append(Data([75, 4]))
        payload.append(Data([0x00]))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.messageType, 0x0C)
        XCTAssertEqual(result?.batteryLevel, 75)
        XCTAssertEqual(result?.deviceInfo?.signalStrength, 4)
        XCTAssertEqual(result?.deviceInfo?.deviceType, "iPhone/iPad")
        XCTAssertNotNil(result?.deviceInfo?.capabilities)
        XCTAssertTrue(result?.deviceInfo?.capabilities?.contains("Hotspot") == true)
    }

    func testContinuityType0CWithoutSignal() {
        var payload = Data([0x4C, 0x00, 0x0C, 0x08])
        payload.append(Data(repeating: 0x00, count: 5))
        payload.append(Data([85]))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.messageType, 0x0C)
        XCTAssertEqual(result?.batteryLevel, 85)
        XCTAssertNil(result?.deviceInfo?.signalStrength)
    }

    func testContinuityType0CInvalidBattery() {
        var payload = Data([0x4C, 0x00, 0x0C, 0x08])
        payload.append(Data(repeating: 0x00, count: 5))
        payload.append(Data([0, 3]))
        payload.append(Data([0x00]))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.messageType, 0x0C)
        XCTAssertNil(result?.batteryLevel)
    }

    func testContinuityType10NearbyAction() {
        var payload = Data([0x4C, 0x00, 0x10, 0x05])
        payload.append(Data(repeating: 0x00, count: 5))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNil(result)
    }

    func testInvalidCompanyID() {
        let payload = Data([0xFF, 0x00, 0x07, 0x19] + [UInt8](repeating: 0, count: 30))
        XCTAssertNil(BluetoothManager.bluetoothParseContinuityManufacturerData(payload))
    }

    func testShortData() {
        let payload = Data([0x4C, 0x00, 0x07])
        XCTAssertNil(BluetoothManager.bluetoothParseContinuityManufacturerData(payload))
    }

    func testEmptyData() {
        let payload = Data()
        XCTAssertNil(BluetoothManager.bluetoothParseContinuityManufacturerData(payload))
    }

    func testBatteryValidationZero() {
        XCTAssertNil(BluetoothManager.bluetoothValidateBatteryValue(0))
    }

    func testBatteryValidationOverflow() {
        XCTAssertNil(BluetoothManager.bluetoothValidateBatteryValue(101))
    }

    func testBatteryValidationValid() {
        XCTAssertEqual(BluetoothManager.bluetoothValidateBatteryValue(50), 50)
        XCTAssertEqual(BluetoothManager.bluetoothValidateBatteryValue(1), 1)
        XCTAssertEqual(BluetoothManager.bluetoothValidateBatteryValue(100), 100)
    }

    func testMultiTLVMessages() {
        var payload = Data([0x4C, 0x00])
        payload.append(Data([0x07, 0x19]))
        payload.append(Data(repeating: 0x00, count: 11))
        payload.append(Data([0x32, 0x2D, 0x50]))
        payload.append(Data(repeating: 0x00, count: 11))
        payload.append(Data([0x0C, 0x08]))
        payload.append(Data(repeating: 0x00, count: 5))
        payload.append(Data([75, 4]))
        payload.append(Data([0x00]))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.messageType == 0x07 || result?.messageType == 0x0C)
        XCTAssertNotNil(result?.batteryLevel)
    }

    func testTruncatedMessage() {
        var payload = Data([0x4C, 0x00, 0x07, 0x19])
        payload.append(Data(repeating: 0x00, count: 5))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNil(result)
    }

    func testType0CShortLength() {
        var payload = Data([0x4C, 0x00, 0x0C, 0x03])
        payload.append(Data(repeating: 0x00, count: 3))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNil(result)
    }

    func testType07ShortLength() {
        var payload = Data([0x4C, 0x00, 0x07, 0x10])
        payload.append(Data(repeating: 0x00, count: 16))

        let result = BluetoothManager.bluetoothParseContinuityManufacturerData(payload)
        XCTAssertNil(result)
    }
}
