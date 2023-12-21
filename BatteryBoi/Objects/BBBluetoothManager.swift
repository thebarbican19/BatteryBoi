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

    private var manager: CBCentralManager!
    private var updates = Set<AnyCancellable>()
    
    static var shared = BluetoothManager()
    
    override init() {
        super.init()
        
        if CBCentralManager.authorization == .allowedAlways {
            self.manager = CBCentralManager(delegate: self, queue: nil)
            
        }
        
        $proximity.dropFirst().removeDuplicates().delay(for: .seconds(10.0), scheduler: RunLoop.main).receive(on: DispatchQueue.main).sink { state in
            if state != .proximate {
                self.proximity = .proximate
                
            }
            
            self.manager.stopScan()
            self.manager.scanForPeripherals(withServices: nil, options: nil)
            
        }.store(in: &updates)

        $broadcasting.debounce(for: .seconds(2), scheduler: RunLoop.main).receive(on: DispatchQueue.main).sink { found in
            for item in found.filter({ $0.state == .connected && $0.characteristics.isEmpty == false }) {
                if let match = self.peripheralMatchDevice(item.peripheral) {
                    if AppManager.shared.devices.contains(match) == false {
                        AppManager.shared.appStoreDevice(match)

                    }
                    
                }
                
            }
            
        }.store(in: &updates)

        $broadcasting.delay(for: .seconds(2), scheduler: RunLoop.main).receive(on: DispatchQueue.main).sink { found in
            if let queued = found.first(where: { $0.state == .pending }) {
                self.manager.connect(queued.peripheral, options: nil)

            }
            else if let queued = found.first(where: { $0.state == .queued && $0.state != .pending }) {
                self.bluetoothUpdateBroadcast(state: .queued, peripheral: queued.peripheral, update: .pending)
                
            }
            
            if let disconnected = found.first(where: { $0.state == .disconnected }) {
                if let match = self.peripheralMatchDevice(disconnected.peripheral) {
                    //AppManager.shared.appStoreEvent(.disconnected, device: match)
                    
                }
                
                self.bluetoothUpdateBroadcast(state: .disconnected, peripheral: disconnected.peripheral, update: .queued)

            }
            
            for item in found.filter({ $0.state != .unavailable }) {
                print("\n👋🏻 - \(item.peripheral.name ?? "Unknown") State: \(item.state) Characteristics: \(item.characteristics.count)\n")
                
            }

        }.store(in: &updates)
        
        $state.removeDuplicates().receive(on: DispatchQueue.main).sink { state in
            if state == .disabled {
                UserDefaults.save(.bluetoothEnabled, value: state.rawValue)
                UserDefaults.save(.bluetoothUpdated, value: Date())

                self.broadcasting = []
                
                self.bluetoothStopScanning()
                
            }
            else {
                UserDefaults.save(.bluetoothEnabled, value: nil)
                UserDefaults.save(.bluetoothUpdated, value: Date())

                self.bluetoothAuthorization()
                
            }
            
        }.store(in: &updates)

        self.bluetoothAuthorization()

    }
    
    public func bluetoothUpdateBroadcast(state:BluetoothConnectionState, peripheral:CBPeripheral? = nil, update:BluetoothConnectionState) {
        DispatchQueue.main.async {
            if let peripheral = peripheral {
                if let index = self.broadcasting.firstIndex(where: { $0.state == state && peripheral == peripheral }) {
                    var payload = self.broadcasting[index]
                    payload.state = update
                    
                    self.broadcasting[index] = payload
                    
                }
                
                if self.broadcasting.firstIndex(where:{ $0.peripheral == peripheral }) == nil {
                    self.broadcasting.append(.init(peripheral))
                    
                }
                
            }
            else {
                if let index = self.broadcasting.firstIndex(where: { $0.state == state }) {
                    var payload = self.broadcasting[index]
                    payload.state = update
                    
                    self.broadcasting[index] = payload
                    
                }
                
            }
            
        }
        
    }
        
    public func bluetoothAuthorization(_ force:Bool = false) {
        if UserDefaults.main.object(forKey: SystemDefaultsKeys.bluetoothEnabled.rawValue) == nil {
            if force == true {
                if CBCentralManager.authorization == .notDetermined {
                    self.manager = CBCentralManager(delegate: self, queue: nil)
                    self.manager.scanForPeripherals(withServices: nil, options: nil)
                    
                }
                
            }
            else {
                if CBCentralManager.authorization == .allowedAlways {
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
        
    }
    
    public func bluetoothCharacteristicAppend(_ characteristic:CBCharacteristic, index:Int) {
        guard self.broadcasting.indices.contains(index) else {
            return
            
        }
        
        if let first = self.broadcasting[index].services.firstIndex(where: { $0 == characteristic }) {
            self.broadcasting[index].characteristics[first] = characteristic
        }
        else {
            self.broadcasting[index].characteristics.append(characteristic)

        }
        
    }
    
    public func bluetoothServicesAppend(_ service:CBService, index:Int) {
        guard self.broadcasting.indices.contains(index) else {
            return
            
        }
        
        if let first = self.broadcasting[index].services.firstIndex(where: { $0 == service }) {
            self.broadcasting[index].services[first] = service
        }
        else {
            self.broadcasting[index].services.append(service)

        }
        
    }
    
    public func bluetoothStopScanning() {
        if self.manager != nil {
            self.manager.stopScan()
            
        }
        
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
                
        if var device = AppManager.shared.devices.first(where: { $0.name == peripheral.name }) {
            device.distance = distance

        }
        
        if distance.state.rawValue <= self.proximity.rawValue {
            self.bluetoothUpdateBroadcast(state: .queued, peripheral: peripheral, update: .queued)
        
        }
        
        UserDefaults.save(.bluetoothUpdated, value: Date())
        
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) { 
        self.bluetoothUpdateBroadcast(state: .pending, peripheral: peripheral, update: .connected)

        peripheral.delegate = self
        peripheral.discoverServices(BluetoothUUID.allCases.compactMap({ $0.uuid }))
        
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.bluetoothUpdateBroadcast(state: .pending, peripheral: peripheral, update: .failed)

    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.bluetoothUpdateBroadcast(state: .connected, peripheral: peripheral, update: .disconnected)

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            
        }
        else {
            if let services = peripheral.services {
                for service in services {
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
            if let index = self.broadcasting.firstIndex(where: { $0.peripheral == peripheral }) {
                if let characteristics = service.characteristics {
                    for characteristic in characteristics {
                        self.bluetoothCharacteristicAppend(characteristic, index: index)
                        
                        peripheral.readValue(for: characteristic)
                        
                        if characteristic.properties.contains(.notify) {
                            peripheral.setNotifyValue(true, for: characteristic)
                            
                        }
                        
                    }
        
                }
                
            }
            else {
                print("No characteristics for " ,peripheral)
                
            }
            
        }
        
    }
    
    func peripheralMatchDevice(_ peripheral: CBPeripheral) -> SystemDeviceObject? {
        var vendor:String? = nil
        var serial:String? = nil
        var model:String? = nil
        var findmy:Bool = false
        var appearance:String? = nil
        var hardware:String? = nil
        var battery:Int? = nil

        if let index = self.broadcasting.firstIndex(where: { $0.peripheral == peripheral }) {
            for characteristic in self.broadcasting[index].characteristics {
                if characteristic.uuid == BluetoothUUID.findmy.uuid {
                    findmy = true
                    
                    if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                        print("Find My Data for \(peripheral.name!):", string)
                        
                    }
                    
                }
                
                if characteristic.uuid == BluetoothUUID.system.uuid {
                    if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                        hardware = string
                        
                    }
                    
                }
                
                if characteristic.uuid == BluetoothUUID.appearance.uuid {
                    if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                        print("System Name for \(peripheral.name!):", string)
                        appearance = string
                        
                    }
                    
                }
                
                if characteristic.uuid == BluetoothUUID.info.uuid {
                    if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                        print("Info Name for \(peripheral.name!):", string)
                        //model = string
                        
                    }
                    
                }
                
                if characteristic.uuid == BluetoothUUID.model.uuid {
                    if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                        model = string
                        
                    }
                    
                }
                
                if characteristic.uuid == BluetoothUUID.vendor.uuid {
                    if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                        vendor = string
                        
                    }
                    
                }
                
                if characteristic.uuid == BluetoothUUID.audiosink.uuid {
                    
                }
                
                if characteristic.uuid == BluetoothUUID.battery.uuid {
                    if let value = characteristic.value?.first.map(Int.init) {
                        battery = value

                    }
                    
                }
                
                if characteristic.uuid == BluetoothUUID.serial.uuid {
                    if let data = characteristic.value, let string = String(data: data, encoding: .utf8) {
                        serial = string
                        
                    }
                    
                }
                
            }
            
        }
        
        if let name = peripheral.name, let model = model {
            let device:SystemDeviceObject = .init(peripheral.identifier, name: name, profile:.init(model: model, vendor: vendor, serial: serial, hardware: hardware, apperance: appearance, findmy: findmy))
            
            return device
            
        }
        else {
            print("No Match for Name \(peripheral.name)")
            print("No Match for Model \(model)")
            print("No Match for Vendor \(vendor)")
            print("No Match for Apperance \(appearance)")
            print("No Match for Hardware \(hardware)")

        }
        
        return nil
        
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let match = self.peripheralMatchDevice(peripheral) else {
            return
            
        }
        
        if characteristic.uuid == BluetoothUUID.battery.uuid {
            if let value = characteristic.value?.first.map(Int.init) {
                BatteryManager.shared.powerStoreEvent(match, battery: value)

            }
            
        }
        
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
}
