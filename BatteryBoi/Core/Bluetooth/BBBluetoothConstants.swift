//
//  BBBluetoothConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation
import CoreBluetooth

public struct BluetoothBroadcastItem: Identifiable, Equatable {
    public static func == (lhs: BluetoothBroadcastItem, rhs: BluetoothBroadcastItem) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state && lhs.proximity == rhs.proximity
    }

    var peripheral: CBPeripheral
    var state: BluetoothConnectionState
    public var id: UUID
    var characteristics: [CBCharacteristic]
    var services: [CBService]
    var proximity: AppDeviceDistanceType = .unknown
    var pendingTimestamp: Date?
    var retryCount: Int = 0

    init(_ peripheral: CBPeripheral, proximity: AppDeviceDistanceType = .unknown, state: BluetoothConnectionState = .queued) {
        self.peripheral = peripheral
        self.state = state
        self.id = peripheral.identifier
        self.characteristics = []
        self.services = []
        self.proximity = proximity
        self.pendingTimestamp = nil
        self.retryCount = 0

        if peripheral.name == nil {
            self.state = .unavailable
        }
        else {
            self.state = state
            if state == .pending {
                self.pendingTimestamp = Date()
            }
        }
    }
}

public enum BluetoothPermissionState: String {
    case allowed
    case undetermined
    case disabled
    case denied
    case off
    case unknown

    var title: String {
        switch self {
            case .allowed: return "PermissionsAllowedLabel".localise()
            case .undetermined: return "PermissionsUndeterminedLabel".localise()
            case .disabled: return "PermissionsDisabledLabel".localise()
            case .denied: return "PermissionsDeniedLabel".localise()
            case .off: return "PermissionsUnavailableLabel".localise()
            case .unknown: return "PermissionsUnknownLabel".localise()
        }
    }
}

public enum BluetoothUUID: String, Hashable, CaseIterable {
    case battery = "00002a19-0000-1000-8000-00805f9b34fb"
    case power = "0000180f-0000-1000-8000-00805f9b34fb"
    case appearance = "00002a01-0000-1000-8000-00805f9b34fb"
    case model = "00002a24-0000-1000-8000-00805f9b34fb"
    case vendor = "00002a29-0000-1000-8000-00805f9b34fb"
    case serial = "00002a25-0000-1000-8000-00805f9b34fb"
    case firmware = "00002a28-0000-1000-8000-00805f9b34fb"
    case system = "00002a23-0000-1000-8000-00805f9b34fb"
    case info = "0000180A-0000-1000-8000-00805F9B34FB"
    case logs = "00001831-0000-1000-8000-00805F9B34FB"
    case headset = "00001108-0000-1000-8000-00805f9b34fb"
    case continuity = "d0611e78-bbb4-4591-a5f8-487910ae4366"
    case nearby = "9fa480e0-4967-4542-9390-d343dc5d04ae"
    case findmy = "6aa50003-6352-4d57-a7b4-003a416fbb0b"
    case audiosink = "0000110b-0000-1000-8000-00805f9b34fb"
    case hid = "00001124-0000-1000-8000-00805f9b34fb"
    case remote = "0000110c-0000-1000-8000-00805f9b34fb"
    case handsfree = "0000111e-0000-1000-8000-00805f9b34fb"

    public var type: String {
        switch self {
            case .battery: return "Battery"
            case .power: return "Power"
            case .appearance: return "Apperance"
            case .model: return "Model"
            case .vendor: return "Vendor"
            case .serial: return "Serial"
            case .firmware: return "Firmware"
            case .system: return "System Info"
            case .info: return "General Info"
            case .logs: return "Logs"
            case .headset: return "Headset Info"
            case .continuity: return "Continuity"
            case .nearby: return "Nearby"
            case .findmy: return "Find My Device"
            case .audiosink: return "Audio Sink"
            case .handsfree: return "Hands Free"
            case .hid: return "Human Interface Device"
            case .remote: return "Remote"
        }
    }

    public var uuid: CBUUID? {
        if self != .findmy && self != .nearby && self != .continuity {
            if let short = self.rawValue.components(separatedBy: "-").first?.suffix(4) {
                return CBUUID(string: String(short))
            }
        }

        return CBUUID(string: self.rawValue)
    }
}

public enum BluetoothConnectionState: String {
    case queued
    case connected
    case pending
    case disconnected
    case failed
    case unavailable
}

struct BluetoothBatteryObject: Decodable, Equatable {
    var general: Double?
    var left: Double?
    var right: Double?
    var percent: Double?

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.general = nil
        self.left = nil
        self.right = nil
        self.percent = nil

        if let percent = try? values.decode(String.self, forKey: .general) {
            let stripped = percent.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

            self.general = Double(stripped)
			
        }

        if let percent = try? values.decode(String.self, forKey: .right) {
            let stripped = percent.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

            self.right = Double(stripped)
			
        }

        if let percent = try? values.decode(String.self, forKey: .left) {
            let stripped = percent.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

            self.left = Double(stripped)
			
        }

        if self.left == nil && self.right == nil && self.general == nil {
            self.percent = nil
			
        }
        else if let min = [self.right, self.left, self.general].compactMap( { $0 }).min() {
            self.percent = min
			
        }
		
    }

    enum CodingKeys: String, CodingKey {
        case right = "device_batteryLevelRight"
        case left = "device_batteryLevelLeft"
        case enclosure = "device_batteryLevel"
        case general = "device_batteryLevelMain"
		
    }
	
}

public struct ContinuityMessageResult {
    var messageType: UInt8
    var batteryLevel: Int?
    var batteryComponents: ContinuityBatteryComponents?
    var deviceInfo: ContinuityDeviceInfo?
	
}

public struct ContinuityBatteryComponents {
    var left: Int?
    var right: Int?
    var enclosure: Int?
    var main: Int?
	
}

public struct ContinuityDeviceInfo {
    var signalStrength: Int?
    var deviceType: String?
    var capabilities: [String]?
	
}

public enum ContinuityMessageType: UInt8, CaseIterable {
    case airDrop = 0x05
    case proximityPairing = 0x07
    case airPlaySource = 0x08
    case airPlayTarget = 0x09
    case tetheringSource = 0x0C
    case nearbyAction = 0x10

    var description: String {
        switch self {
            case .airDrop: return "AirDrop"
            case .proximityPairing: return "Proximity Pairing"
            case .airPlaySource: return "AirPlay Source"
            case .airPlayTarget: return "AirPlay Target"
            case .tetheringSource: return "Tethering Source"
            case .nearbyAction: return "Nearby Action"
			
        }
		
    }
	
}
