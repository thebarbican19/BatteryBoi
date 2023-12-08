//
//  BBBluetoothModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/21/23.
//

import Foundation
import CoreBluetooth

struct BluetoothBroadcastItem:Equatable,Hashable {
    static func == (lhs: BluetoothBroadcastItem, rhs: BluetoothBroadcastItem) -> Bool {
        lhs.peripheral == rhs.peripheral && lhs.state == rhs.state

    }
    
    var peripheral:CBPeripheral
    var state:BluetoothConnectionState
    var id:UUID
    var updated:Date
    var characteristics = Array<String>()
    var proximity:SystemDeviceDistanceType = .unknown
    
    init(_ peripheral:CBPeripheral, proximity:SystemDeviceDistanceType = .unknown, state:BluetoothConnectionState = .queued) {
        self.peripheral = peripheral
        self.state = state
        self.id = peripheral.identifier
        self.updated = Date()
        self.proximity = proximity
        
        if peripheral.name == nil {
            self.state = .unavailable
            
        }
        else {
            self.state = state

        }
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        
    }
    
}

enum BluetoothPermissionState:String {
    case allowed
    case undetermined
    case disabled
    case denied
    case off
    case unknown
    
}

enum BluetoothUUID:String,Hashable,CaseIterable {
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
    
    public var type:String {
        switch self {
            case .battery:return "Battery"
            case .power:return "Power"
            case .appearance:return "Apperance"
            case .model:return "Model"
            case .vendor:return "Vendor"
            case .serial:return "Serial"
            case .firmware:return "Firmware"
            case .system:return "System Info"
            case .info:return "General Info"
            case .logs:return "Logs"
            case .headset:return "Headset Info"
            case .continuity:return "Continuity"
            case .nearby:return "Nearby"
            case .findmy:return "Find My Device"
            case .audiosink:return "Audio Sink"
            case .handsfree:return "Hands Free"
            case .hid:return "Human Interface Device" // Mouse/Trackpad
            case .remote:return "Remote"

        }
        
    }

    public var uuid:CBUUID? {
        if self != .findmy && self != .nearby && self != .continuity {
            if let short = self.rawValue.components(separatedBy: "-").first?.suffix(4) {
                return CBUUID(string: String(short))
                
            }
            
        }
        
        return CBUUID(string: self.rawValue)

    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self)
        
    }
    
}

enum BluetoothConnectionState:String {
    case queued
    case connected
    case pending
    case disconnected
    case failed
    case unavailable
    
}

struct BluetoothBatteryObject:Decodable,Equatable {
    var general:Double?
    var left:Double?
    var right:Double?
    var percent:Double?

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
        else if let min = [self.right, self.left, self.general].compactMap({ $0 }).min() {
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

//struct BluetoothObject:Decodable,Equatable {
//    static func == (lhs: BluetoothObject, rhs: BluetoothObject) -> Bool {
//        return lhs.address == rhs.address && lhs.connected == rhs.connected && lhs.distance == rhs.distance
//        
//    }
//    
//    let id:UUID? = nil
//    let address: String
//    let firmware: String?
//    var battery:BluetoothBatteryObject
//    let type:BluetoothDeviceObject
//    var distance:BluetoothDistanceObject
//
//    var peripheral:CBPeripheral? = nil
//    var updated:Date
//    var device: String?
//    var connected: BluetoothState
//    
//    public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//                
//        self.battery = try! BluetoothBatteryObject(from: decoder)
//        self.address = try! values.decode(String.self, forKey: .address).lowercased().replacingOccurrences(of: ":", with: "-")
//        self.firmware = try? values.decode(String.self, forKey: .firmware)
//        self.connected = .disconnected
//        self.device = nil
//        self.updated = Date.distantPast
//        self.distance = .init(0.0)
//        
//        if let distance = try? values.decode(String.self, forKey: .rssi) {
//            if let value = Double(distance) {
//                self.distance = .init(value)
//                
//            }
//
//        }
//       
//        if let type = try? values.decode(String.self, forKey: .type) {
//            let subtype = try? values.decode(String.self, forKey: .product)
//            let vendor = try? values.decode(String.self, forKey: .product)
//
//            self.type = BluetoothDeviceObject(type, subtype:subtype, vendor: vendor)
//
//        }
//        else {
//            self.type = BluetoothDeviceObject("")
//            
//        }
//        
//    }
//    
//    enum CodingKeys: String, CodingKey {
//        case address = "device_address"
//        case firmware = "device_firmwareVersion"
//        case type = "device_minorType"
//        case vendor = "device_vendorID"
//        case product = "device_productID"
//        case rssi = "device_rssi"
//
//    }
//    
//}
//
//typealias BluetoothObjectContainer = [String: BluetoothObject]
//
//enum BluetoothState:Int {
//    case connected = 1
//    case disconnected = 0
//        
//    var status:String {
//        switch self {
//            case .connected : return "Connected"
//            case .disconnected : return "Not Connected"
//            
//        }
//        
//    }
//    
//    var boolean:Bool {
//        switch self {
//            case .connected : return true
//            case .disconnected : return false
//            
//        }
//        
//    }
//    
//}
