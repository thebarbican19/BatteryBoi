//
//  BBBluetoothManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/22/23.
//  Fixed by Toby Fox on 1/11/24
//

import Foundation
import Combine
import IOBluetooth
import IOKit.ps
import Cocoa
import CoreBluetooth
import EnalogSwift

enum BluetoothConnectionState {
    case connected
    case disconnected
    case failed
    case unavailable
    
}

enum BluetoothVendor: String {
    case apple = "0x004C"
    case samsung = "0x0050"
    case microsoft = "0x0052"
    case bose = "0x1001"
    case sennheiser = "0x1002"
    case sony = "0x1003"
    case jbl = "0x1004"
    case skullcandy = "0x1005"
    case beats = "0x1006"
    case jabra = "0x1007"
    case audioTechnica = "0x1008"
    case unknown = ""
    
}

enum BluetoothScriptType:String {
    case profiler = "BBProfilerList"
    case oreg = "BBIOREGList"
    
}

enum BluetoothDistanceType:Int {
    case proximate
    case near
    case far
    case unknown
    
}

struct BluetoothDeviceObject {
    var type:BluetoothDeviceType
    var subtype:BluetoothDeviceSubtype?
    var vendor:BluetoothVendor?
    var icon:String
    
    init(_ type:String, subtype:String? = nil, vendor:String? = nil) {
        self.type = BluetoothDeviceType(rawValue: type.lowercased()) ?? .other
        self.subtype = BluetoothDeviceSubtype(rawValue: subtype ?? "")
        self.vendor = BluetoothVendor(rawValue: vendor ?? "")
        
        if let subtype = self.subtype {
            self.icon = subtype.icon
            
        }
        else {
            self.icon = self.type.icon
            
        }
        
    }
    
}

enum BluetoothDeviceSubtype: String {
    case airpodsMax = "0x200A"
    case airpodsProVersionOne = "0x200E"
    case airpodsVersionTwo = "0x200F"
    case airpodsVersionOne = "0x2002"
    case unknown = ""
    
    var icon:String {
        switch self {
            case .airpodsMax : return "headphones"
            case .airpodsProVersionOne : return "airpods.gen3"
            default : return "airpods"
            
        }
        
    }
    
}

enum BluetoothDeviceType:String,Decodable {
    case mouse = "mouse"
    case headphones = "headphones"
    case gamepad = "gamepad"
    case speaker = "speaker"
    case keyboard = "keyboard"
    case other = "other"
    
    var name:String {
        switch self {
            case .mouse:return "BluetoothDeviceMouseLabel".localise()
            case .headphones:return "BluetoothDeviceHeadphonesLabel".localise()
            case .gamepad:return "BluetoothDeviceGamepadLabel".localise()
            case .speaker:return "BluetoothDeviceSpeakerLabel".localise()
            case .keyboard:return "BluetoothDeviceKeyboardLabel".localise()
            case .other:return "BluetoothDeviceOtherLabel".localise()
            
        }
        
    }
    
    var icon:String {
        switch self {
            case .mouse:return "magicmouse.fill"
            case .headphones:return "headphones"
            case .gamepad:return "gamecontroller.fill"
            case .speaker:return "hifispeaker.2.fill"
            case .keyboard:return "keyboard.fill"
            case .other:return ""
            
        }
        
    }
    
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

struct BluetoothObject:Decodable,Equatable {
    static func == (lhs: BluetoothObject, rhs: BluetoothObject) -> Bool {
        return lhs.address == rhs.address && lhs.connected == rhs.connected && lhs.distance == rhs.distance
        
    }
    
    let address: String
    let firmware: String?
    var battery:BluetoothBatteryObject
    let type:BluetoothDeviceObject
    var distance:BluetoothDistanceType

    var updated:Date
    var device: String?
    var connected: BluetoothState
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            self.battery = try! BluetoothBatteryObject(from: decoder)
            self.address = (try? values.decode(String.self, forKey: .address))?.lowercased().replacingOccurrences(of: ":", with: "-") ?? ""
            self.firmware = try? values.decode(String.self, forKey: .firmware)
            self.connected = .disconnected
            self.device = nil
            self.updated = Date.distantPast
            
            if let distance = try? values.decode(String.self, forKey: .rssi) {
                if let value = Double(distance) {
                    if value >= -50 && value <= -20 {
                        self.distance = .proximate
                        
                    }
                    else if value >= -70 && value < -50 {
                        self.distance = .near
                        
                    }
                    else {
                        self.distance = .far
                        
                    }
                    
                }
                else {
                    self.distance = .unknown
                    
                }
                
            }
            else {
                self.distance = .unknown
                
            }
            
            if let type = try? values.decode(String.self, forKey: .type) {
                let subtype = try? values.decode(String.self, forKey: .product)
                let vendor = try? values.decode(String.self, forKey: .product)
                
                self.type = BluetoothDeviceObject(type, subtype:subtype, vendor: vendor)
                
            }
            else {
                self.type = BluetoothDeviceObject("")
                
            }
        } catch {
            // Handle the decoding error here (e.g., log it, print an error message, or set default values)
            print("Error decoding BluetoothObject: \(error)")
            self.battery = try BluetoothBatteryObject(from: decoder)
            self.address = ""
            self.firmware = nil
            self.connected = .disconnected
            self.device = nil
            self.updated = Date.distantPast
            self.distance = .unknown
            self.type = BluetoothDeviceObject("")
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case address = "device_address"
        case firmware = "device_firmwareVersion"
        case type = "device_minorType"
        case vendor = "device_vendorID"
        case product = "device_productID"
        case rssi = "device_rssi"

    }
    
}

typealias BluetoothObjectContainer = [String: BluetoothObject]

enum BluetoothState:Int {
    case connected = 1
    case disconnected = 0
        
    var status:String {
        switch self {
            case .connected : return "Connected"
            case .disconnected : return "Not Connected"
            
        }
        
    }
    
    var boolean:Bool {
        switch self {
            case .connected : return true
            case .disconnected : return false
            
        }
        
    }
    
}

class BluetoothManager:ObservableObject {
    static var shared = BluetoothManager()
    
    @Published var list = Array<BluetoothObject>()
    @Published var connected = Array<BluetoothObject>()
    @Published var icons = Array<String>()

    private var updates = Set<AnyCancellable>()
        
    init() {
        AppManager.shared.appTimer(15).dropFirst(1).receive(on: DispatchQueue.main).sink { _ in
            self.bluetoothList(.oreg)
            self.bluetoothList(.profiler)

        }.store(in: &updates)
        
        AppManager.shared.$device.receive(on: DispatchQueue.global()).sink { device in
            if let device = device {
                if device.connected == .disconnected {
                    _ = self.bluetoothUpdateConnetion(device, state: .connected)
                    
                }
                
            }
            
        }.store(in: &updates)
        
        $list.receive(on: DispatchQueue.main).sink { list in
            self.connected = list.filter({ $0.connected == .connected })
            self.icons = self.connected.map({ $0.type.icon })
            
            for device in list {
                print("\n\(device.device ?? "") (\(device.address)) - \(device.connected.status)")

            }
                                    
        }.store(in: &updates)
        
        DispatchQueue.main.async {
            self.bluetoothList(.oreg, initialize: true)
            self.bluetoothList(.profiler)

            switch self.list.filter({ $0.connected == .connected }).count {
                case 0 : AppManager.shared.menu = .settings
                default : AppManager.shared.menu = .devices
                
            }
            
        }
        
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
    public func bluetoothUpdateConnetion(_ device:BluetoothObject, state:BluetoothState) -> BluetoothConnectionState {
        if let device = IOBluetoothDevice(addressString: device.address) {
            if device.isConnected() {
                if state == .connected {
                    return .connected
                    
                }
                else {
                    let result = device.closeConnection()
                    if result == kIOReturnSuccess {
                        return .disconnected

                    }
                    else {
                        print("Failed to disconnect from the device. Error: \(result)")
                        return .failed

                    }
                    
                }
                
            }
            else {
                if state == .connected {
                    let result = device.openConnection()
                    if result == kIOReturnSuccess {
                        return .connected
                        
                    }
                    else {
                        print("Failed to connect to the device. Error: \(result)")
                        return .failed
                        
                    }
                    
                }
                
            }
            
        } 
       
        return .unavailable
        
    }
        
    private func bluetoothList(_ type:BluetoothScriptType, initialize:Bool = false) {
        if FileManager.default.fileExists(atPath: "/usr/bin/python3") {
            if let script = Bundle.main.path(forResource: type.rawValue, ofType: "py") {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
                process.arguments = [script]
                
                let pipe = Pipe()
                process.standardOutput = pipe
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    
                    if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        if let stripped = output.data(using: .utf8) {
                            do {
                                let object = try JSONDecoder().decode([BluetoothObjectContainer].self, from: stripped)
                                let values = object.flatMap { $0.values }
                                
                                for item in IOBluetoothDevice.pairedDevices() {
                                    if let device = item as? IOBluetoothDevice {
                                        if let index = values.firstIndex(where: {$0.address == device.addressString }) {
                                            let status:BluetoothState = device.isConnected() ? .connected : .disconnected
                                            
                                            var updated = values[index]
                                            updated.device = device.name
                                            
                                            if status != updated.connected {
                                                updated.connected = status
                                                updated.updated = Date()
                                                
                                            }
                                            
                                            if let index = self.list.firstIndex(where: {$0.address == device.addressString }) {
                                                if self.list[index].battery.general != nil && updated.battery.general == nil  {
                                                    updated.battery.general = self.list[index].battery.general
                                                    updated.updated = Date()
                                                    
                                                }
                                                
                                                if self.list[index].battery.left != nil && updated.battery.left == nil  {
                                                    updated.battery.left = self.list[index].battery.left
                                                    updated.updated = Date()
                                                    
                                                }
                                                
                                                if self.list[index].battery.right != nil && updated.battery.right == nil  {
                                                    updated.battery.right = self.list[index].battery.right
                                                    updated.updated = Date()
                                                    
                                                }
                                                
                                                if self.list[index].battery.percent != nil && updated.battery.percent == nil  {
                                                    updated.battery.percent = self.list[index].battery.percent
                                                    updated.updated = Date()
                                                    
                                                }
                                                
                                                if self.list[index].distance != updated.distance {
                                                    updated.distance = self.list[index].distance
                                                    updated.updated = Date()
                                                    
                                                }
                                                
                                                self.list[index] = updated
                                                
                                            }
                                            else {
                                                if updated.type.type != .other {
                                                    self.list.append(updated)
                                                    
                                                }
                                                
                                                device.register(forDisconnectNotification: self, selector: #selector(self.bluetoothDeviceUpdated))
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                }
                                
                                if initialize == true {
                                    IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(self.bluetoothDeviceUpdated))
                                    
                                }
                                
                            }
                            catch {
                                print("Failed to convert output data to object - \(error)")
                                
                            }
                            
                        }
                        
                    }
                    
                    
                }
                catch {
                    print("Error running Python script: \(error)")
                    
                }
                
            }
            else {
                EnalogManager.main.ingest(SystemEvents.fatalError, description: "Python Library not Found")
                
            }
            
        }
                
    }
    
    @objc private func bluetoothDeviceUpdated() {
        for item in IOBluetoothDevice.pairedDevices() {
            if let device = item as? IOBluetoothDevice {
                if let index = self.list.firstIndex(where: {$0.address == device.addressString }) {
                    DispatchQueue.main.async {
                        let status:BluetoothState = device.isConnected() ? .connected : .disconnected
                        var update = self.list[index]
                    
                        if update.connected != status {
                            update.updated = Date()
                            update.connected = status
                            
                            self.list[index] = update
                                                        
                        }
                        
                    }
                    
                }
                
            }
            
        }
                
    }

}
