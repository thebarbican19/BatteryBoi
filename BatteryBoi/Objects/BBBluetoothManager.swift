//
//  BBBluetoothManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/22/23.
//

import Foundation
import Combine
import CoreBluetooth
import EnalogSwift

class BluetoothManager:NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var state:BluetoothPermissionState = .unknown
    @Published var broadcasting:[BluetoothBroadcastItem] = []
    @Published var proximity:SystemDeviceDistanceType = .proximate
    @Published var connecting:Bool = false

    private var manager: CBCentralManager!
    private var updates = Set<AnyCancellable>()
    
    static var shared = BluetoothManager()
    
    override init() {
        super.init()
        
        if CBCentralManager.authorization == .allowedAlways {
            self.manager = CBCentralManager(delegate: self, queue: nil)
            
        }
        
        $connecting.receive(on: DispatchQueue.global()).delay(for: .seconds(20), scheduler: RunLoop.main).removeDuplicates().sink { state in
            if state == true {
                if let index = self.broadcasting.firstIndex(where: { $0.peripheral.name != nil && $0.state == .pending }) {
                    self.broadcasting[index].state = .queued
                    self.broadcasting[index].updated = Date()
                    
                }
                
            }
            
        }.store(in: &updates)
        
        $broadcasting.removeDuplicates().receive(on: DispatchQueue.main).sink { items in
            if CBCentralManager.authorization == .allowedAlways {
                if let index = self.broadcasting.firstIndex(where: { $0.peripheral.name != nil && $0.state == .queued }) {
                    self.connecting = true

                    self.broadcasting[index].state = .pending
                    self.broadcasting[index].updated = Date()
                    
                    self.manager.connect(self.broadcasting[index].peripheral, options: nil)
                    
                }
                
                if let _ = self.broadcasting.firstIndex(where: { $0.state != .queued }) {
                    self.connecting = false
                    
                }
                
            }
            else {
                print("Not authorixed")
                
            }
            
        }.store(in: &updates)

        self.bluetoothAuthorization()

    }
    
    public func bluetoothAuthorization(_ force:Bool = false) {
        if force == true {
            if CBCentralManager.authorization == .notDetermined {
                self.manager = CBCentralManager(delegate: self, queue: nil)
                self.manager.scanForPeripherals(withServices: nil, options: nil)

            }
            
        }
        
        DispatchQueue.main.async {
            switch CBCentralManager.authorization {
                case .allowedAlways : self.state = .allowed
                case .notDetermined : self.state = .undetermined
                default : self.state = .denied

            }
            
        }
        
    }
    
    public func bluetoothServicesAppend(_ id:CBUUID) -> String {
        if let match = BluetoothUUID.allCases.filter({ $0.uuid == id }).first {
            return match.type

        }
        else {
            return id.uuidString

        }
        
    }
    
    public func bluetoothStopScanning() {
        self.manager.stopScan()
        
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if self.state == .allowed {
            self.manager.scanForPeripherals(withServices: nil, options: nil)

        }
        
        DispatchQueue.main.async {
            switch CBCentralManager.authorization {
                case .allowedAlways : self.state = .allowed
                case .notDetermined : self.state = .undetermined
                default : self.state = .denied

            }

        }
        
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let distance:SystemDeviceDistanceObject = .init(Double(truncating: RSSI))
                
        if var device = AppManager.shared.list.first(where: { $0.name == peripheral.name }) {
            device.distance = distance

        }
        
        if distance.state.rawValue <= self.proximity.rawValue || AppManager.shared.list.filter({ $0.name == peripheral.name }).isEmpty == false {
            if let index = self.broadcasting.firstIndex(where: { $0.peripheral.name == peripheral.name }) {
                if self.broadcasting[index].state != .unavailable && self.broadcasting[index].state != .connected {
                    self.broadcasting[index].state = .queued
                    self.broadcasting[index].updated = Date()
                    self.broadcasting[index].proximity = distance.state

                }

            }
            else {
                self.broadcasting.append(.init(peripheral, proximity: distance.state))
                
            }

        }
        
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {  
        if let index = self.broadcasting.firstIndex(where: { $0.peripheral == peripheral }) {
            self.broadcasting[index].state = .connected
            self.broadcasting[index].updated = Date()

        }
        
        peripheral.delegate = self
        peripheral.discoverServices(BluetoothUUID.allCases.compactMap({ $0.uuid }))
        
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let index = self.broadcasting.firstIndex(where: { $0.peripheral.name == peripheral.name }) {
            self.broadcasting[index].state = .failed
            self.broadcasting[index].updated = Date()

        }
        
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let index = self.broadcasting.firstIndex(where: { $0.peripheral.name == peripheral.name }) {
            self.broadcasting[index].state = .disconnected
            self.broadcasting[index].updated = Date()

        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            
        }
        else {
            if let index = self.broadcasting.firstIndex(where: { $0.peripheral.name == peripheral.name }) {
                self.broadcasting[index].state = .connected
                self.broadcasting[index].updated = Date()
            
                if let index = self.broadcasting.firstIndex(where: { $0.peripheral.name == peripheral.name }) {
                    if let services = self.broadcasting[index].peripheral.services {
                        for service in services {
                            let id = self.bluetoothServicesAppend(service.uuid)
                            
                            if self.broadcasting[index].characteristics.contains(id) == false {
                                self.broadcasting[index].characteristics.append(id)
                                self.broadcasting[index].updated = Date()

                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
            if let services = peripheral.services {
                print("Found \(services.count) for ", peripheral)
                for service in services {
                    print("Characteristics UUID" ,service.uuid)
                    
                    peripheral.discoverCharacteristics(nil, for: service)

                }
                
            }
            
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")

        }
        else {
            if let index = self.broadcasting.firstIndex(where: { $0.peripheral.name == peripheral.name }) {
                if let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        let id = self.bluetoothServicesAppend(characteristic.uuid)
                        
                        if self.broadcasting[index].characteristics.contains(id) == false {
                            self.broadcasting[index].characteristics.append(id)
                            self.broadcasting[index].updated = Date()

                        }
                        
                    }
                    
                }
                
            }
            
            if let characteristics = service.characteristics {
                var name:String? = peripheral.name
                var vendor:String? = nil
                var serial:String? = nil
                
                for characteristic in characteristics {
                    print("characteristic" ,characteristic.uuid)
                    if characteristic.uuid == BluetoothUUID.battery.uuid {
                        
                    }
                    
                    if characteristic.uuid == BluetoothUUID.vendor.uuid {
                        if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                            print("Vendor Name:", string)
                            vendor = string
                            
                        }
                        
                    }
                   
                    if characteristic.uuid == BluetoothUUID.serial.uuid {
                        if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                            serial = string
                            
                        }
                        
                    }
                    
                    if let name = name {
                        let profile:SystemDeviceProfileObject = .init(serial: serial, vendor: vendor)
                        let device:SystemDeviceObject = .init(peripheral.identifier, name: name, profile: profile)
                        
                        AppManager.shared.appUpdateList(device)

                    }
                    else {
                        print("could not update list with " ,peripheral)
                        
                    }

                    if characteristic.uuid == BluetoothUUID.nearby.uuid {
                        print("FOUND NEARBY FOR \(peripheral.name)")
                        
                    }
                    
                    if characteristic.uuid == BluetoothUUID.continuity.uuid {
                        print("FOUND CONTINUITY FOR \(peripheral.name)")
                        
                    }
                    
                    switch characteristic.uuid {
                        case CBUUID(string: "110D"): print("TYPE: HEADPHONES")
                        case CBUUID(string: "1812"): print("TYPE: MOUSE")
                        case CBUUID(string: "110A"): print("TYPE: SPEAKERS")
                        default : print("UNKNOWN")
                        
                    }
                    
                    peripheral.readValue(for: characteristic)
                    
                    if characteristic.properties.contains(.notify) {
                        peripheral.setNotifyValue(true, for: characteristic)
                        
                    }
                    
                }
                
            }
            else {
                print("No characteristics for " ,peripheral)
                
            }
        }
        
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if broadcasting.first(where: { $0.peripheral == peripheral }) != nil {
            print("Updating \(peripheral.name)")
            
            if characteristic.uuid == BluetoothUUID.battery.uuid {
                if let value = characteristic.value?.first.map(Int.init) {
                    AppManager.shared.appStoreEvent(.depleted, peripheral: peripheral, battery: value)

                }
                
            }
            
            if characteristic.uuid == BluetoothUUID.continuity.uuid {
                print("Continuity Found")
                print("characteristic.value" ,characteristic.value?.first)
                
                if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                    print("Continuity:",string)
                    
                }
                
            }
            
            if characteristic.uuid == BluetoothUUID.nearby.uuid {
                print("Nearby Found")
                
                if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                    print("Nearby:",string)
                    
                }
                
            }
            
            if characteristic.uuid == BluetoothUUID.findmy.uuid {
                print("Found My Found")

            }
            
            if characteristic.uuid == BluetoothUUID.headset.uuid {
                print("headsetFound")

            }
            
        }
        
//        if let match = BluetoothManager.shared.list.first(where: { $0.device == peripheral.name }) {
//            print("Match: " ,match)
//            
//        }
        
    }
    
    /*
    init() {
//        AppManager.shared.appTimer(15).dropFirst(1).receive(on: DispatchQueue.main).sink { _ in
//            self.bluetoothList(.oreg)
//            self.bluetoothList(.profiler)
//
//        }.store(in: &updates)
        
        AppManager.shared.$device.receive(on: DispatchQueue.global()).sink { device in
            if let device = device {
                if device.connected == .disconnected {
                    _ = self.bluetoothUpdateConnetion(device, state: .connected)
                    
                }
                
            }
            
        }.store(in: &updates)
        
        #if DEBUG
            CentralManager.shared.$active.receive(on: DispatchQueue.global()).sink { device in
                if device == nil {
                    CentralManager.shared.startScanning()

                }
                
            }.store(in: &updates)

        #endif
        
//        $list.receive(on: DispatchQueue.main).sink { list in
//            self.connected = list.filter({ $0.connected == .connected })
//            self.icons = self.connected.map({ $0.type.icon })
//            
//            CentralManager.shared.startScanning()
//            
//            for device in list {
//                print("\n\(device.device ?? "") (\(device.address)) - \(device.connected.status)")
//
//            }
//                                    
//        }.store(in: &updates)
        
        DispatchQueue.main.async {
//            self.bluetoothList(.oreg, initialize: true)
//            self.bluetoothList(.profiler)
            
            switch self.list.filter({ $0.connected == .connected }).count {
                case 0 : AppManager.shared.menu = .settings
                default : AppManager.shared.menu = .devices
                
            }
            
            CentralManager.shared.startScanning()

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
        
//    private func bluetoothList(_ type:BluetoothScriptType, initialize:Bool = false) {
//        if let response = ProcessManager.shared.processWithScript(type.rawValue) {
//            if let stripped = response.data(using: .utf8) {
//                do {
//                    let object = try JSONDecoder().decode([BluetoothObjectContainer].self, from: stripped)
//                    let values = object.flatMap { $0.values }
//                    
//                    for item in IOBluetoothDevice.pairedDevices() {
//                        if let device = item as? IOBluetoothDevice {
//                            if let index = values.firstIndex(where: {$0.address == device.addressString }) {
//                                let status:BluetoothState = device.isConnected() ? .connected : .disconnected
//                                
//                                var updated = values[index]
//                                updated.device = device.name
//                                
//                                if status != updated.connected {
//                                    updated.connected = status
//                                    updated.updated = Date()
//                                    
//                                }
//                                
//                                if let index = self.list.firstIndex(where: {$0.address == device.addressString }) {
//                                    if self.list[index].battery.general != nil && updated.battery.general == nil  {
//                                        updated.battery.general = self.list[index].battery.general
//                                        updated.updated = Date()
//                                        
//                                    }
//                                    
//                                    if self.list[index].battery.left != nil && updated.battery.left == nil  {
//                                        updated.battery.left = self.list[index].battery.left
//                                        updated.updated = Date()
//                                        
//                                    }
//                                    
//                                    if self.list[index].battery.right != nil && updated.battery.right == nil  {
//                                        updated.battery.right = self.list[index].battery.right
//                                        updated.updated = Date()
//                                        
//                                    }
//                                    
//                                    if self.list[index].battery.percent != nil && updated.battery.percent == nil  {
//                                        updated.battery.percent = self.list[index].battery.percent
//                                        updated.updated = Date()
//                                        
//                                    }
//                                    
//                                    if self.list[index].distance != updated.distance {
//                                        updated.distance = self.list[index].distance
//                                        updated.updated = Date()
//                                        
//                                    }
//                                    
//                                    self.list[index] = updated
//                                    
//                                }
//                                else {
//                                    if updated.type.type != .other {
//                                        self.list.append(updated)
//                                        
//                                    }
//                                    
//                                    device.register(forDisconnectNotification: self, selector: #selector(self.bluetoothDeviceUpdated))
//                                    
//                                }
//                                
//                            }
//                            
//                        }
//                        
//                    }
//                    
//                    if initialize == true {
//                        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(self.bluetoothDeviceUpdated))
//                        
//                    }
//                    
//                }
//                catch {
//                    print("Failed to convert output data to object - \(error)")
//                    
//                }
//                
//            }
//            
//        }
//                
//    }

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
     */
    
}
