//
//  BBBluetoothManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/22/23.
//

import Foundation
import Combine
import CoreBluetooth

#if os(macOS)
import IOBluetooth
import IOKit
#endif

public class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var state: BluetoothPermissionState = .unknown
    @Published var broadcasting: [BluetoothBroadcastItem] = []
    @Published var proximity: SystemDeviceDistanceType = .proximate

    private var manager: CBCentralManager!
    private var updates = Set<AnyCancellable>()

    static var shared = BluetoothManager()
    
    override init() {
        super.init()

        if CBCentralManager.authorization == .allowedAlways {
            self.manager = CBCentralManager(delegate: self, queue: nil)

        }

        #if os(macOS)
        Timer.publish(every: 30.0, on: .main, in: .common).autoconnect().sink { _ in
            self.logConnectedBluetoothDeviceBatteries()
        }.store(in: &updates)
        #endif

        $proximity.dropFirst().removeDuplicates().delay(for: .seconds(10.0), scheduler: RunLoop.main).receive(on: DispatchQueue.main).sink { state in
            if state != .proximate {
                self.proximity = .proximate

            }

            self.bluetoothStopScanning()
            self.bluetoothStartScanning()

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
                var dataMap: [BluetoothUUID: Data] = [:]
                for characteristic in item.characteristics {
                    if let type = BluetoothUUID.allCases.first(where: { $0.uuid == characteristic.uuid }), let data = characteristic.value {
                        dataMap[type] = data
                    }
                }
                let parsed = Self.parseCharacteristicData(dataMap)
                let batteryInfo = parsed.battery != nil ? " Battery: \(parsed.battery!)%" : ""
                print("\n👋🏻 - \(item.peripheral.name ?? "Unknown") State: \(item.state) Characteristics: \(item.characteristics.count)\(batteryInfo)\n")
                
                if let battery = parsed.battery, let name = item.peripheral.name {
                    self.saveDeviceAndBattery(name: name, identifier: item.peripheral.identifier, battery: battery, profile: parsed.profile)
                }

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

        // Start IOKit Polling
        Timer.publish(every: 300, on: .main, in: .common).autoconnect().sink { _ in
            self.fetchIOKitBatteryDevices()
        }.store(in: &updates)
        
        // Initial fetch
        self.fetchIOKitBatteryDevices()
    }

    public static func parseIOKitDictionary(_ dict: [String: Any]) -> (name: String, battery: Int, profile: SystemDeviceProfileObject)? {
        if let name = dict["Name"] as? String,
           let battery = dict["BatteryPercent"] as? Int {

            let model = dict["DeviceModel"] as? String ?? "Bluetooth Device"
            let vendor = dict["VendorName"] as? String
            let serial = dict["SerialNumber"] as? String

            let profile = SystemDeviceProfileObject(model: model, vendor: vendor, serial: serial, hardware: nil, apperance: nil, findmy: false)

            return (name, battery, profile)
        }
        return nil
    }

    public func fetchIOKitBatteryDevices() {
        #if os(macOS)
        let matchDict = IOServiceMatching("IOBluetoothDevice")
        var iterator: io_iterator_t = 0

        if IOServiceGetMatchingServices(kIOMasterPortDefault, matchDict, &iterator) == kIOReturnSuccess {
            var device = IOIteratorNext(iterator)
            while device != 0 {

                var properties: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(device, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                   let dict = properties?.takeRetainedValue() as? [String: Any] {

                    if let parsed = Self.parseIOKitDictionary(dict) {
                        self.saveDeviceAndBattery(name: parsed.name, identifier: UUID(), battery: parsed.battery, profile: parsed.profile)
                    }
                }

                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }
        #endif
    }

    public func bluetoothUpdateBroadcast(state: BluetoothConnectionState, peripheral: CBPeripheral? = nil, update: BluetoothConnectionState) {
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

    public func bluetoothStartScanning() {
        if self.manager != nil && self.manager.state == .poweredOn {
            self.manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    public func bluetoothAuthorization(_ force: Bool = false) {
        if UserDefaults.main.object(forKey: SystemDefaultsKeys.bluetoothEnabled.rawValue) == nil {
            if force == true {
                if CBCentralManager.authorization == .notDetermined {
                    self.manager = CBCentralManager(delegate: self, queue: nil)

                }

            }
            else {
                if CBCentralManager.authorization == .allowedAlways {

                }

            }

            DispatchQueue.main.async {
                switch CBCentralManager.authorization {
                    case .allowedAlways: self.state = .allowed
                    case .notDetermined: self.state = .undetermined
                    default: self.state = .denied

                }

            }

        }

    }

    public func bluetoothCharacteristicAppend(_ characteristic: CBCharacteristic, index: Int) {
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

    public func bluetoothServicesAppend(_ service: CBService, index: Int) {
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
                case .allowedAlways: self.state = .allowed
                case .notDetermined: self.state = .undetermined
                default: self.state = .denied

            }

        }

    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let distance: SystemDeviceDistanceObject = .init(Double(truncating: RSSI))

        var batteryLevel: Int? = nil

        #if os(macOS)
        if let name = peripheral.name {
            if let ioKitBattery = getIOKitBatteryLevel(deviceName: name) {
                batteryLevel = ioKitBattery
            }
        }
        #endif

        if batteryLevel == nil {
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                batteryLevel = parseContinuityManufacturerData(manufacturerData)
            }
        }

        if let battery = batteryLevel, let name = peripheral.name {
            let profile = SystemDeviceProfileObject(model: "Bluetooth Device", vendor: nil, serial: nil, hardware: nil, apperance: nil, findmy: false)
            self.saveDeviceAndBattery(name: name, identifier: peripheral.identifier, battery: battery, profile: profile)
        }

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
    
    private func saveDeviceAndBattery(name: String, identifier: UUID, battery: Int, profile: SystemDeviceProfileObject) {
        if let context = AppManager.shared.appStorageContext() {
            context.perform {
                let tempDevice = SystemDeviceObject(identifier, name: name, profile: profile)
                if let match = SystemDeviceObject.match(tempDevice, context: context) {
                    AppManager.shared.appStoreDevice(match)
                    BatteryManager.shared.powerStoreEvent(match, battery: battery)
                } else {
                    AppManager.shared.appStoreDevice(tempDevice)
                    BatteryManager.shared.powerStoreEvent(tempDevice, battery: battery)
                }
            }
        }
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
                print("No characteristics for", peripheral)

            }

        }

    }

    public static func parseCharacteristicData(_ dataMap: [BluetoothUUID: Data]) -> (profile: SystemDeviceProfileObject, battery: Int?) {
        var vendor: String?
        var serial: String?
        var model: String?
        var findmy: Bool = false
        var appearance: String?
        var hardware: String?
        var battery: Int?

        if let data = dataMap[.findmy], let string = String(data: data, encoding: .utf8) {
            findmy = true
            print("Find My Data:", string)
        }

        if let data = dataMap[.system], let string = String(data: data, encoding: .utf8) {
            hardware = string
        }

        if let data = dataMap[.appearance], let string = String(data: data, encoding: .utf8) {
            appearance = string
        }

        if let data = dataMap[.model], let string = String(data: data, encoding: .utf8) {
            model = string
        }

        if let data = dataMap[.vendor], let string = String(data: data, encoding: .utf8) {
            vendor = string
        }

        if let data = dataMap[.battery] {
            battery = data.first.map(Int.init)
        }

        if let data = dataMap[.serial], let string = String(data: data, encoding: .utf8) {
            serial = string
        }

        let profile = SystemDeviceProfileObject(
            model: model ?? "",
            vendor: vendor,
            serial: serial,
            hardware: hardware,
            apperance: appearance,
            findmy: findmy
        )

        return (profile, battery)
    }

    func peripheralMatchDevice(_ peripheral: CBPeripheral) -> SystemDeviceObject? {
        guard let index = self.broadcasting.firstIndex(where: { $0.peripheral == peripheral }) else {
            return nil
        }

        var dataMap: [BluetoothUUID: Data] = [:]

        for characteristic in self.broadcasting[index].characteristics {
            if let type = BluetoothUUID.allCases.first(where: { $0.uuid == characteristic.uuid }),
               let data = characteristic.value {
                dataMap[type] = data
            }
        }

        let parsed = Self.parseCharacteristicData(dataMap)

        if let name = peripheral.name, !parsed.profile.model.isEmpty {
            let device = SystemDeviceObject(
                peripheral.identifier,
                name: name,
                profile: parsed.profile
            )

            return device
        }
        else {
            print("No Match for Name \(peripheral.name ?? "Unknown")")
            print("No Match for Model \(parsed.profile.model)")

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

    #if os(macOS)
    func logConnectedBluetoothDeviceBatteries() {
        let deviceClasses = ["AppleBluetoothHIDKeyboard", "BNBMouseDevice", "AppleDeviceManagementHIDEventService", "IOBluetoothHIDDriver", "IOBluetoothDevice"]

        print("\n🔋 Checking IOKit for connected Bluetooth devices...\n")

        for deviceClass in deviceClasses {
            var iterator = io_iterator_t()
            var object = io_object_t()
            let port: mach_port_t

            if #available(macOS 12.0, *) {
                port = kIOMainPortDefault
            }
            else {
                port = kIOMasterPortDefault
            }

            guard let matchingDict = IOServiceMatching(deviceClass) else {
                continue
            }

            let result = IOServiceGetMatchingServices(port, matchingDict, &iterator)
            if result == KERN_SUCCESS {
                repeat {
                    object = IOIteratorNext(iterator)
                    if object != 0 {
                        let name = IORegistryEntryCreateCFProperty(object, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String ?? IORegistryEntryCreateCFProperty(object, "Name" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
                        let percent = IORegistryEntryCreateCFProperty(object, "BatteryPercent" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int
                        let serial = IORegistryEntryCreateCFProperty(object, "SerialNumber" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
                        let vendor = IORegistryEntryCreateCFProperty(object, "VendorName" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
                        let model = IORegistryEntryCreateCFProperty(object, "DeviceModel" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String ?? deviceClass

                        if let name = name, let percent = percent {
                            print("🔋 [\(deviceClass)] \(name): \(percent)%")

                            let profile = SystemDeviceProfileObject(model: model, vendor: vendor, serial: serial, hardware: nil, apperance: nil, findmy: false)
                            self.saveDeviceAndBattery(name: name, identifier: UUID(), battery: percent, profile: profile)
                        }

                        IOObjectRelease(object)
                    }
                } while object != 0
                IOObjectRelease(iterator)
            }
        }
    }

    func getIOKitBatteryLevel(deviceName: String) -> Int? {
        let deviceClasses = ["AppleBluetoothHIDKeyboard", "BNBMouseDevice", "AppleDeviceManagementHIDEventService"]

        for deviceClass in deviceClasses {
            var iterator = io_iterator_t()
            var object = io_object_t()
            let port: mach_port_t

            if #available(macOS 12.0, *) {
                port = kIOMainPortDefault
            }
            else {
                port = kIOMasterPortDefault
            }

            guard let matchingDict = IOServiceMatching(deviceClass) else {
                continue
            }

            let result = IOServiceGetMatchingServices(port, matchingDict, &iterator)
            if result == KERN_SUCCESS {
                repeat {
                    object = IOIteratorNext(iterator)
                    if object != 0 {
                        if let name = IORegistryEntryCreateCFProperty(object, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String, name == deviceName {
                            if let percent = IORegistryEntryCreateCFProperty(object, "BatteryPercent" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                                IOObjectRelease(object)
                                IOObjectRelease(iterator)
                                return percent
                            }
                        }
                        IOObjectRelease(object)
                    }
                } while object != 0
                IOObjectRelease(iterator)
            }
        }
        return nil
    }
    #endif

    func parseContinuityManufacturerData(_ data: Data) -> Int? {
        guard data.count >= 2 else {
            return nil
        }

        let companyID = UInt16(data[0]) | (UInt16(data[1]) << 8)
        guard companyID == 0x004C else {
            return nil
        }

        var offset = 2
        while offset < data.count {
            guard offset + 1 < data.count else {
                break
            }

            let type = data[offset]
            let length = Int(data[offset + 1])

            guard offset + 2 + length <= data.count else {
                break
            }

            if type == 0x07 && length >= 25 {
                let batteryLeft = data[offset + 13]
                let batteryRight = data[offset + 14]
                let batteryCase = data[offset + 15]

                let batteries = [batteryLeft, batteryRight, batteryCase].filter { $0 > 0 && $0 <= 100 }
                if batteries.isEmpty == false {
                    return Int(batteries.min() ?? 0)
                }
            }

            offset += 2 + length
        }

        return nil
    }

    deinit {
        self.updates.forEach { $0.cancel() }

    }

}
