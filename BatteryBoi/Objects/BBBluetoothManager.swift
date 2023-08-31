//
//  BBBluetoothManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/22/23.
//

import Foundation
import Combine
import IOBluetooth
import IOKit.ps
import Cocoa

enum BluetoothDeviceType:String,Decodable {
    case mouse = "mouse"
    case headphones = "headphones"
    case gamepad = "gamepad"
    case speaker = "speaker"
    case keyboard = "keyboard"
    case other = "other"
    
}

struct BluetoothBatteryObject:Decodable,Equatable {
    var general:Double?
    var left:Double?
    var right:Double?
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.general = nil
        self.left = nil
        self.right = nil

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
        return lhs.address == rhs.address && lhs.connected == rhs.connected
        
    }
    
    let address: String
    let firmware: String?
    let vendor: String?
    let battery:BluetoothBatteryObject
    let type:BluetoothDeviceType
    
    var updated:Date
    var device: String?
    var connected: BluetoothState
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.battery = try! BluetoothBatteryObject(from: decoder)
        self.address = try! values.decode(String.self, forKey: .address).lowercased().replacingOccurrences(of: ":", with: "-")
        self.firmware = try? values.decode(String.self, forKey: .firmware)
        self.vendor = try? values.decode(String.self, forKey: .vendor)
        self.connected = .disconnected
        self.device = nil
        self.updated = Date.distantPast
        
        if let type = try? values.decode(String.self, forKey: .type) {
            self.type = BluetoothDeviceType(rawValue: type.lowercased()) ?? .other

        }
        else {
            self.type = .other
            
        }
        
    }
    
    enum CodingKeys: String, CodingKey {
        case address = "device_address"
        case firmware = "device_firmwareVersion"
        case type = "device_minorType"
        case vendor = "device_vendorID"
        
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
    
    private var updates = Set<AnyCancellable>()

    init() {
        AppManager.shared.appTimer(15).dropFirst(1).sink { _ in
            self.bluetoothList()
            
        }.store(in: &updates)
        
        self.bluetoothList()
    
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
        
    private func bluetoothList() {
        if let script = Bundle.main.path(forResource: "BBProfilerList", ofType: "py") {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = [script]

            let pipe = Pipe()
            process.standardOutput = pipe
                          
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                
                do {
                    let object = try JSONDecoder().decode([BluetoothObjectContainer].self, from: data)
                    let values = object.flatMap { $0.values }
                    
                    for item in IOBluetoothDevice.pairedDevices() {
                        if let device = item as? IOBluetoothDevice {
                            if let index = values.firstIndex(where: {$0.address == device.addressString }) {
                                var updated = values[index]
                                updated.device = device.name
                                
                                if let index = self.list.firstIndex(where: {$0.address == device.addressString }) {
                                    self.list[index] = updated
                                    
                                }
                                else {
                                    self.list.append(updated)

                                }
                                
                            }
                            
                            device.register(forDisconnectNotification: self, selector: #selector(self.bluetoothDeviceUpdated))
                            
                        }
                        
                    }
                    
                    IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(self.bluetoothDeviceUpdated))
                     
                }
                catch {
                    print("Failed to convert output data to object - \(error)")

                }
                
            } 
            catch {
                print("Error running Python script: \(error)")
                
            }
            
        }
        else {
            print("Python script not found in the app bundle.")
            
        }
                
    }
    
    @objc private func bluetoothDeviceUpdated() {
        for item in IOBluetoothDevice.pairedDevices() {
            if let device = item as? IOBluetoothDevice {
                if let index = self.list.firstIndex(where: {$0.address == device.addressString }) {
                    let status:BluetoothState = device.isConnected() ? .connected : .disconnected

                    if self.list[index].connected != status {
                        self.list[index].updated = Date()
                        self.list[index].connected = status
                        
                    }

                }
                
            }
            
        }
                
    }
    
}
