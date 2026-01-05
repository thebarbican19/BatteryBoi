//
//  BBBluetoothManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/22/23.
//

import Foundation
import Combine
import CoreBluetooth
import CryptoKit

#if os(macOS)
import IOBluetooth
import IOKit
import AppKit

#else
import UIKit

#endif

public class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var state: BluetoothPermissionState = .unknown
    @Published var broadcasting: [BluetoothBroadcastItem] = []
    @Published var proximity: AppDeviceDistanceType = .proximate

    private var manager: CBCentralManager!
    private var updates = Set<AnyCancellable>()
    private var discovered = Set<UUID>()
    private var burst = false
    private var peripheralStates: [UUID: BluetoothConnectionState] = [:]

    static var shared = BluetoothManager()
    private let logger = LogManager.shared
    
    override init() {
        super.init()

        logger.logInfo("Initializing BluetoothManager")

        if CBCentralManager.authorization == .allowedAlways {
            self.manager = CBCentralManager(delegate: self, queue: nil)
            logger.logInfo("CoreBluetooth manager initialized with authorization")
        }
        else {
            logger.logWarning("CoreBluetooth authorization not granted: \(CBCentralManager.authorization.rawValue)")
        }

        #if os(macOS)
        Timer.publish(every: 30.0, on: .main, in: .common).autoconnect().sink { _ in
            self.bluetoothLogConnectedDeviceBatteries()
			
        }.store(in: &updates)
        #endif

        $proximity.dropFirst().removeDuplicates().receive(on: DispatchQueue.main).sink { state in
            self.bluetoothStopScanning()
            DispatchQueue.main.async {
                self.bluetoothStartScanning()
            }
            
            if state != .proximate {
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                    self.proximity = .proximate
                }
            }

        }.store(in: &updates)

        $broadcasting.debounce(for: .seconds(2), scheduler: RunLoop.main).receive(on: DispatchQueue.main).sink { found in
            for item in found.filter({ $0.state == .connected && $0.characteristics.isEmpty == false }) {
                if let match = self.bluetoothMatchDevice(item.peripheral) {
                    var isNewDevice = false
                    if let context = AppManager.shared.appStorageContext() {
                        let existingDevice = AppDeviceObject.match(match, context: context)
                        if existingDevice == nil {
                            isNewDevice = true
                            self.logger.logInfo("Storing new device: \(match.name) (ID: \(match.id))")
                            AppManager.shared.appStoreDevice(match)
                        }
                        else {
                            self.logger.logDebug("Device already exists: \(match.name)")
                        }
                    }
                    else {
                        self.logger.logError("Cannot check device existence - SwiftData context unavailable")
                    }

                    var batteryLevel: Int? = nil
                    for characteristic in item.characteristics {
                        if characteristic.uuid == BluetoothUUID.battery.uuid {
                            if let value = characteristic.value?.first.map(Int.init) {
                                batteryLevel = value
                                break

                            }

                        }

                    }

                    if isNewDevice && batteryLevel != nil {
                        self.logger.logInfo("New device connected: \(match.name) (\(batteryLevel!)%)")
                        BatteryManager.shared.powerStoreEvent(match, battery: batteryLevel, force: .deviceConnected)
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
                if let match = self.bluetoothMatchDevice(disconnected.peripheral) {
                    var batteryLevel: Int? = nil
                    for characteristic in disconnected.characteristics {
                        if characteristic.uuid == BluetoothUUID.battery.uuid {
                            if let value = characteristic.value?.first.map(Int.init) {
                                batteryLevel = value
                                break
                            }
                        }
                    }

                    self.logger.logInfo("Device disconnected: \(match.name)" + (batteryLevel != nil ? " (last battery: \(batteryLevel!)%)" : ""))
                    BatteryManager.shared.powerStoreEvent(match, battery: batteryLevel, force: .deviceDisconnected)
                }

                self.bluetoothUpdateBroadcast(state: .disconnected, peripheral: disconnected.peripheral, update: .queued)
            }

            if let failed = found.first(where: { $0.state == .failed && $0.retryCount < 3 }) {
                self.bluetoothUpdateBroadcast(state: .failed, peripheral: failed.peripheral, update: .queued)

                if let name = failed.peripheral.name {
                    self.logger.logInfo("Retrying device \(name) (attempt \(failed.retryCount + 1) of 3)")
                }
            }

            for item in found.filter({ $0.state != .unavailable }) {
                var dataMap: [BluetoothUUID: Data] = [:]
                for characteristic in item.characteristics {
                    if let type = BluetoothUUID.allCases.first(where: { $0.uuid == characteristic.uuid }), let data = characteristic.value {
                        dataMap[type] = data
                    }
                }
                let parsed = Self.bluetoothParseCharacteristicData(dataMap)
                let batteryInfo = parsed.battery != nil ? " Battery: \(parsed.battery!)%" : ""
                
                if let battery = parsed.battery, let name = item.peripheral.name {
                    self.logger.logInfo("Saving battery data for \(name): \(battery)%")
                    self.bluetoothSaveDeviceAndBattery(name: name, identifier: item.peripheral.identifier, battery: battery, profile: parsed.profile)
                }

            }

        }.store(in: &updates)
        
        $state.removeDuplicates().receive(on: DispatchQueue.main).sink { state in
            self.logger.logInfo("Bluetooth state changed to: \(state)")
            if state == .disabled {
                UserDefaults.save(.bluetoothEnabled, value: state.rawValue)
                UserDefaults.save(.bluetoothUpdated, value: Date())

                self.broadcasting = []

                self.bluetoothStopScanning()
                self.logger.logInfo("Bluetooth scanning stopped (disabled)")
            }
            else {
                UserDefaults.save(.bluetoothEnabled, value: nil)
                UserDefaults.save(.bluetoothUpdated, value: Date())

                self.bluetoothAuthorization()
            }
        }.store(in: &updates)

        self.bluetoothAuthorization()

//        NotificationCenter.default.addObserver(self, selector: #selector(bluetoothRecheckAuthorization), name: .CKAccountStatusDidChange, object: nil)
        
        #if os(macOS)
            NotificationCenter.default.addObserver(self, selector: #selector(bluetoothRecheckAuthorization), name: NSApplication.willBecomeActiveNotification, object: nil)
        #elseif os(iOS)
            NotificationCenter.default.addObserver(self, selector: #selector(bluetoothRecheckAuthorization), name: UIApplication.willEnterForegroundNotification, object: nil)
        #endif

        Timer.publish(every: 300, on: .main, in: .common).autoconnect().sink { _ in
            self.bluetoothFetchIOKitBatteryDevices()
			
        }.store(in: &updates)
        
        Timer.publish(every: 5.0, on: .main, in: .common).autoconnect().sink { _ in
            self.bluetoothReadConnectedDevicesRSSI()
			
        }.store(in: &updates)

        Timer.publish(every: 60.0, on: .main, in: .common).autoconnect().sink { _ in
            self.bluetoothPerformScanCycle()
        }.store(in: &updates)

        Timer.publish(every: 300.0, on: .main, in: .common).autoconnect().sink { _ in
            self.bluetoothPerformBurstScan()
        }.store(in: &updates)

        Timer.publish(every: 10.0, on: .main, in: .common).autoconnect().sink { _ in
            self.bluetoothCheckPendingTimeouts()
        }.store(in: &updates)

        Timer.publish(every: 600.0, on: .main, in: .common).autoconnect().sink { _ in
            self.bluetoothCleanupStaleStates()
        }.store(in: &updates)

		self.bluetoothFetchIOKitBatteryDevices()
		self.bluetoothPerformBurstScan()

    }

    private static func bluetoothParseIOKitDictionary(_ dict: [String: Any]) -> (name: String, battery: Int, profile: AppDeviceProfileObject, address: String?)? {
        if let name = dict["Name"] as? String,
           let battery = dict["BatteryPercent"] as? Int {

            let model = dict["DeviceModel"] as? String ?? "Bluetooth Device"
            let vendor = dict["VendorName"] as? String
            let serial = dict["SerialNumber"] as? String

            var address: String? = nil
            if let addressData = dict["Address"] as? Data {
                address = addressData.map { String(format: "%02x", $0) }.joined(separator: ":")
            }
            else if let addressString = dict["Address"] as? String {
                address = addressString
            }
            else if let addressString = dict["DeviceAddress"] as? String {
                address = addressString
            }

            let profile = AppDeviceProfileObject(model: model, vendor: vendor, serial: serial, hardware: nil, apperance: nil, findmy: false)

            return (name, battery, profile, address)
        }
        return nil
    }

    private static func bluetoothGenerateStableUUID(address: String?, serial: String?, name: String) -> UUID {
        if let address = address, address.isEmpty == false {
            let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
            let data = Data((namespace.uuidString + address).utf8)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            let uuidString = "\(hashString.prefix(8))-\(hashString.dropFirst(8).prefix(4))-\(hashString.dropFirst(12).prefix(4))-\(hashString.dropFirst(16).prefix(4))-\(hashString.dropFirst(20).prefix(12))"
            return UUID(uuidString: uuidString) ?? UUID()
        }
        else if let serial = serial, serial.isEmpty == false {
            let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
            let data = Data((namespace.uuidString + serial + name).utf8)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            let uuidString = "\(hashString.prefix(8))-\(hashString.dropFirst(8).prefix(4))-\(hashString.dropFirst(12).prefix(4))-\(hashString.dropFirst(16).prefix(4))-\(hashString.dropFirst(20).prefix(12))"
            return UUID(uuidString: uuidString) ?? UUID()
        }
        else {
            let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
            let data = Data((namespace.uuidString + "iokit-bluetooth-" + name).utf8)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            let uuidString = "\(hashString.prefix(8))-\(hashString.dropFirst(8).prefix(4))-\(hashString.dropFirst(12).prefix(4))-\(hashString.dropFirst(16).prefix(4))-\(hashString.dropFirst(20).prefix(12))"
            return UUID(uuidString: uuidString) ?? UUID()
        }
    }

    private func bluetoothFetchIOKitBatteryDevices() {
        #if os(macOS)
        logger.logDebug("Fetching IOKit Bluetooth battery devices")
        let matchDict = IOServiceMatching("IOBluetoothDevice")
        var iterator: io_iterator_t = 0

        if IOServiceGetMatchingServices(kIOMasterPortDefault, matchDict, &iterator) == kIOReturnSuccess {
            var device = IOIteratorNext(iterator)
            var deviceCount = 0
            while device != 0 {
                var properties: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(device, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                   let dict = properties?.takeRetainedValue() as? [String: Any] {

                    if let parsed = Self.bluetoothParseIOKitDictionary(dict) {
                        let stableID = Self.bluetoothGenerateStableUUID(address: parsed.address, serial: parsed.profile.serial, name: parsed.name)
                        if let address = parsed.address {
                            logger.logInfo("Found IOKit Bluetooth device: \(parsed.name) [\(address)] - \(parsed.battery)%")
                        }
                        else {
                            logger.logInfo("Found IOKit Bluetooth device: \(parsed.name) - \(parsed.battery)%")
                        }
                        self.bluetoothSaveDeviceAndBattery(name: parsed.name, identifier: stableID, battery: parsed.battery, profile: parsed.profile, address: parsed.address)
                        deviceCount += 1
                    }
                }

                IOObjectRelease(device)
                device = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
            logger.logDebug("IOKit scan completed: found \(deviceCount) Bluetooth devices")
        }
        else {
            logger.logError("Failed to get IOKit Bluetooth devices")
        }
        #endif
    }

    private func bluetoothUpdateBroadcast(state: BluetoothConnectionState, peripheral: CBPeripheral? = nil, update: BluetoothConnectionState) {
        DispatchQueue.main.async {
            if let peripheral = peripheral {
                if let currentState = self.peripheralStates[peripheral.identifier] {
                    if (update == .queued || update == .pending) && (currentState == .pending || currentState == .connected) {
                        self.logger.logDebug("Skipping duplicate queue for \(peripheral.name ?? "Unknown") - already \(currentState)")
                        return
                    }
                }

                self.peripheralStates[peripheral.identifier] = update

                if let index = self.broadcasting.firstIndex(where: { $0.state == state && peripheral == peripheral }) {
                    var payload = self.broadcasting[index]
                    payload.state = update

                    if update == .pending {
                        payload.pendingTimestamp = Date()
                    }
                    else {
                        payload.pendingTimestamp = nil
                    }

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

                    if update == .pending {
                        payload.pendingTimestamp = Date()
                    }
                    else {
                        payload.pendingTimestamp = nil
                    }

                    self.broadcasting[index] = payload

                }

            }

        }

    }

    private func bluetoothPerformScanCycle() {
        let activePeripheralIDs = Set(self.broadcasting.filter {
            $0.state == .connected || $0.state == .pending
        }.map { $0.peripheral.identifier })

        self.discovered = self.discovered.intersection(activePeripheralIDs)

        self.bluetoothStartScanning()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.bluetoothStopScanning()
        }
    }

    private func bluetoothPerformBurstScan() {
        logger.logInfo("Starting burst scan for far devices")
        self.burst = true

        let activePeripheralIDs = Set(self.broadcasting.filter {
            $0.state == .connected || $0.state == .pending
        }.map { $0.peripheral.identifier })

        self.discovered = self.discovered.intersection(activePeripheralIDs)

        let previousProximity = self.proximity
        self.proximity = .far

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.bluetoothStopScanning()
            self.burst = false
            self.proximity = previousProximity
            self.logger.logInfo("Burst scan completed")
        }
    }

    private func bluetoothCheckPendingTimeouts() {
        let now = Date()
        let timeoutInterval: TimeInterval = 30.0

        for (index, item) in self.broadcasting.enumerated() {
            if item.state == .pending, let timestamp = item.pendingTimestamp {
                let elapsed = now.timeIntervalSince(timestamp)

                if elapsed > timeoutInterval {
                    var updated = self.broadcasting[index]
                    updated.retryCount += 1
                    updated.state = .failed
                    updated.pendingTimestamp = nil

                    self.broadcasting[index] = updated

                    if let name = updated.peripheral.name {
                        self.logger.logWarning("Connection timeout for \(name) after \(Int(elapsed))s (attempt \(updated.retryCount) of 3)")
                    }
                }
            }
        }
    }

    public func bluetoothStartScanning() {
        if self.manager != nil && self.manager.state == .poweredOn {
            #if os(iOS)
            if self.proximity == .far {
                logger.logInfo("Starting BLE wide scan (iOS)")
                self.manager.scanForPeripherals(withServices: nil, options: nil)
            }
            else {
                let services = [BluetoothUUID.power.uuid].compactMap { $0 }
                logger.logInfo("Starting BLE scan for battery services (iOS)")
                self.manager.scanForPeripherals(withServices: services, options: nil)
            }
            #else
            logger.logInfo("Starting BLE scan for all services (macOS)")
            self.manager.scanForPeripherals(withServices: nil, options: nil)
            #endif
        }
        else {
            logger.logWarning("Cannot start scanning - manager state: \(self.manager?.state.rawValue ?? -1)")
        }
    }

    public func bluetoothAuthorizationState() {
        let status = CBCentralManager.authorization

        switch status {
            case .allowedAlways: self.state = .allowed
            case .notDetermined: self.state = .undetermined
            case .denied: self.state = .denied
            case .restricted: self.state = .denied
            @unknown default: self.state = .denied

        }

    }

    public func bluetoothAuthorization(_ force: Bool = false) {
        if UserDefaults.main.object(forKey: AppDefaultsKeys.bluetoothEnabled.rawValue) == nil {
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
                self.bluetoothAuthorizationState()

            }

        }

    }

    @objc private func bluetoothRecheckAuthorization() {
        self.bluetoothAuthorization()
        
    }

    private func bluetoothCharacteristicAppend(_ characteristic: CBCharacteristic, index: Int) {
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

    private func bluetoothServicesAppend(_ service: CBService, index: Int) {
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
            logger.logDebug("Stopping BLE scan")
            self.manager.stopScan()
        }
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if self.state == .allowed {
            self.bluetoothPerformScanCycle()

        }

        DispatchQueue.main.async {
            self.bluetoothAuthorizationState()

        }

    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let distance: AppDeviceDistanceObject = .init(Double(truncating: RSSI))

        if discovered.contains(peripheral.identifier) == true {
            self.bluetoothUpdateDeviceDistance(peripheral: peripheral, rssi: RSSI)
            UserDefaults.save(.bluetoothUpdated, value: Date())
            return
        }

        discovered.insert(peripheral.identifier)
        logger.logDebug("Discovered peripheral: \(peripheral.name ?? "Unknown") - RSSI: \(RSSI) - Distance: \(distance.state)")

        var batteryLevel: Int? = nil

        #if os(macOS)
        if let name = peripheral.name {
            if let ioKitBattery = bluetoothGetIOKitBatteryLevel(deviceName: name) {
                batteryLevel = ioKitBattery
                logger.logDebug("Found IOKit battery for \(name): \(ioKitBattery)%")
            }
        }
        #endif

        if batteryLevel == nil {
            if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
                if let result = Self.bluetoothParseContinuityManufacturerData(manufacturerData) {
                    batteryLevel = result.batteryLevel
                    if let battery = batteryLevel {
                        let messageTypeName = result.messageType == 0x0C ? "Tethering" : result.messageType == 0x07 ? "Pairing" : String(format: "0x%02X", result.messageType)
                        logger.logDebug("Parsed Continuity \(messageTypeName) battery: \(battery)%")
                        if let signal = result.deviceInfo?.signalStrength {
                            logger.logDebug("Signal strength: \(signal) bars")
                        }

                    }

                }

            }

        }

        if let battery = batteryLevel, let name = peripheral.name {
            logger.logInfo("Saving advertisement battery for \(name): \(battery)%")
            let profile = AppDeviceProfileObject(model: "Bluetooth Device", vendor: nil, serial: nil, hardware: nil, apperance: nil, findmy: false)
            let stableID = Self.bluetoothGenerateStableUUID(address: nil, serial: nil, name: name)
            self.bluetoothSaveDeviceAndBattery(name: name, identifier: stableID, battery: battery, profile: profile)
        }

        if var device = AppManager.shared.devices.first(where: { $0.name == peripheral.name }) {
            device.distance = distance

        }

        self.bluetoothUpdateDeviceDistance(peripheral: peripheral, rssi: RSSI)

        if distance.state.rawValue <= self.proximity.rawValue || self.burst == true {
            self.bluetoothUpdateBroadcast(state: .queued, peripheral: peripheral, update: .queued)
            if self.burst == true {
                logger.logDebug("Queuing far device from burst scan: \(peripheral.name ?? "Unknown")")
            }

        }

        UserDefaults.save(.bluetoothUpdated, value: Date())

    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.logInfo("✓ Connected to peripheral: \(peripheral.name ?? "Unknown") (ID: \(peripheral.identifier))")
        self.bluetoothUpdateBroadcast(state: .pending, peripheral: peripheral, update: .connected)

        peripheral.delegate = self
        peripheral.discoverServices(BluetoothUUID.allCases.compactMap({ $0.uuid }))
        logger.logDebug("Discovering services for: \(peripheral.name ?? "Unknown")")
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            logger.logError("✗ Failed to connect to \(peripheral.name ?? "Unknown"): \(error.localizedDescription)")
        }
        else {
            logger.logError("✗ Failed to connect to \(peripheral.name ?? "Unknown"): Unknown error")
        }
        self.bluetoothUpdateBroadcast(state: .pending, peripheral: peripheral, update: .failed)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            logger.logWarning("Peripheral disconnected unexpectedly: \(peripheral.name ?? "Unknown") - \(error.localizedDescription)")
        }
        else {
            logger.logInfo("Peripheral disconnected: \(peripheral.name ?? "Unknown")")
        }
        self.bluetoothUpdateBroadcast(state: .connected, peripheral: peripheral, update: .disconnected)
    }
    
    private func bluetoothSaveDeviceAndBattery(name: String, identifier: UUID, battery: Int, profile: AppDeviceProfileObject, address: String? = nil) {
        if let context = AppManager.shared.appStorageContext() {
            var tempDevice = AppDeviceObject(identifier, name: name, profile: profile)
            if let address = address {
                tempDevice.address = address
            }
            if let match = AppDeviceObject.match(tempDevice, context: context) {
                logger.logInfo("📊 Saving battery event for existing device: \(name) (\(battery)%)")
                AppManager.shared.appStoreDevice(match)
                BatteryManager.shared.powerStoreEvent(match, battery: battery)
            }
            else {
                logger.logInfo("📊 Creating new device and battery event: \(name) (\(battery)%)")
                AppManager.shared.appStoreDevice(tempDevice)
                BatteryManager.shared.powerStoreEvent(tempDevice, battery: battery)
            }
        }
        else {
            logger.logError("Cannot save device - SwiftData context unavailable")
        }
    }
    
    private func bluetoothReadConnectedDevicesRSSI() {
        for item in self.broadcasting.filter({ $0.state == .connected }) {
            item.peripheral.readRSSI()
        }
    }

    private func bluetoothUpdateDeviceDistance(peripheral: CBPeripheral, rssi: NSNumber) {
        let distance: AppDeviceDistanceObject = .init(Double(truncating: rssi))

        DispatchQueue.main.async {
            if let index = AppManager.shared.devices.firstIndex(where: { $0.id == peripheral.identifier }) {
                AppManager.shared.devices[index].distance = distance
				
            }
			else if let index = AppManager.shared.devices.firstIndex(where: { $0.name == peripheral.name }) {
                AppManager.shared.devices[index].distance = distance
				
            }
			
        }
		
    }

    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            return
        }

        self.bluetoothUpdateDeviceDistance(peripheral: peripheral, rssi: RSSI)
        
        if let index = self.broadcasting.firstIndex(where: { $0.peripheral == peripheral }) {
            var item = self.broadcasting[index]
            item.proximity = AppDeviceDistanceObject(Double(truncating: RSSI)).state
            self.broadcasting[index] = item
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logger.logError("Failed to discover services for \(peripheral.name ?? "Unknown"): \(error.localizedDescription)")
        }
        else {
            if let services = peripheral.services {
                logger.logDebug("Discovered \(services.count) services for \(peripheral.name ?? "Unknown")")
                for service in services {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            logger.logError("Failed to discover characteristics for \(peripheral.name ?? "Unknown"): \(error.localizedDescription)")
        }
        else {
            if let index = self.broadcasting.firstIndex(where: { $0.peripheral == peripheral }) {
                if let characteristics = service.characteristics {
                    logger.logDebug("Discovered \(characteristics.count) characteristics for service \(service.uuid) on \(peripheral.name ?? "Unknown")")
                    for characteristic in characteristics {
                        self.bluetoothCharacteristicAppend(characteristic, index: index)
                        peripheral.readValue(for: characteristic)

                        if characteristic.properties.contains(.notify) {
                            peripheral.setNotifyValue(true, for: characteristic)
                            logger.logDebug("Enabled notifications for characteristic \(characteristic.uuid)")
                        }
                    }
                }
            }
            else {
                logger.logWarning("Could not find peripheral \(peripheral.name ?? "Unknown") in broadcasting list")
            }
        }
    }

    private static func bluetoothParseCharacteristicData(_ dataMap: [BluetoothUUID: Data]) -> (profile: AppDeviceProfileObject, battery: Int?) {
        var vendor: String?
        var serial: String?
        var model: String?
        var findmy: Bool = false
        var appearance: String?
        var hardware: String?
        var battery: Int?

        if let data = dataMap[.findmy], let string = String(data: data, encoding: .utf8) {
            findmy = true
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

        let profile = AppDeviceProfileObject(
            model: model ?? "",
            vendor: vendor,
            serial: serial,
            hardware: hardware,
            apperance: appearance,
            findmy: findmy
        )

        return (profile, battery)
    }

    private func bluetoothMatchDevice(_ peripheral: CBPeripheral) -> AppDeviceObject? {
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

        let parsed = Self.bluetoothParseCharacteristicData(dataMap)

        if let name = peripheral.name, parsed.profile.model.isEmpty == false {
            let device = AppDeviceObject(
                peripheral.identifier,
                name: name,
                profile: parsed.profile
            )

            return device

        }
        else {

        }

        return nil
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.logError("Failed to read characteristic for \(peripheral.name ?? "Unknown"): \(error.localizedDescription)")
            return
        }

        guard let match = self.bluetoothMatchDevice(peripheral) else {
            logger.logDebug("No device match found for peripheral: \(peripheral.name ?? "Unknown")")
            return
        }

        if characteristic.uuid == BluetoothUUID.battery.uuid {
            if let value = characteristic.value?.first.map(Int.init) {
                logger.logInfo("📱 Battery characteristic updated for \(match.name): \(value)%")
                BatteryManager.shared.powerStoreEvent(match, battery: value)
            }
        }
        else {
            logger.logDebug("Characteristic \(characteristic.uuid) updated for \(peripheral.name ?? "Unknown")")
        }
    }

    #if os(macOS)
    private func bluetoothLogConnectedDeviceBatteries() {
        logger.logDebug("Scanning IOKit for connected Bluetooth HID devices")
        let deviceClasses = ["AppleBluetoothHIDKeyboard", "BNBMouseDevice", "AppleDeviceManagementHIDEventService", "IOBluetoothHIDDriver", "IOBluetoothDevice"]
        var totalDevicesFound = 0

        for deviceClass in deviceClasses {
            var iterator = io_iterator_t()
            var object = io_object_t()
            let port: mach_port_t = kIOMainPortDefault

            guard let matchingDict = IOServiceMatching(deviceClass) else {
                logger.logWarning("Failed to create matching dict for \(deviceClass)")
                continue
            }

            let result = IOServiceGetMatchingServices(port, matchingDict, &iterator)
            if result == KERN_SUCCESS {
                var classDeviceCount = 0
                repeat {
                    object = IOIteratorNext(iterator)
                    if object != 0 {
                        let name = IORegistryEntryCreateCFProperty(object, "Product" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String ?? IORegistryEntryCreateCFProperty(object, "Name" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
                        let percent = IORegistryEntryCreateCFProperty(object, "BatteryPercent" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int
                        let serial = IORegistryEntryCreateCFProperty(object, "SerialNumber" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
                        let vendor = IORegistryEntryCreateCFProperty(object, "VendorName" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
                        let model = IORegistryEntryCreateCFProperty(object, "DeviceModel" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String ?? deviceClass

                        var address: String? = nil
                        if let addressData = IORegistryEntryCreateCFProperty(object, "Address" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Data {
                            address = addressData.map { String(format: "%02x", $0) }.joined(separator: ":")
                        }
                        else if let addressString = IORegistryEntryCreateCFProperty(object, "Address" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String {
                            address = addressString
                        }

                        if let name = name, let percent = percent {
                            let stableID = Self.bluetoothGenerateStableUUID(address: address, serial: serial, name: name)
                            if let address = address {
                                logger.logInfo("🔋 IOKit HID device [\(deviceClass)]: \(name) [\(address)] - \(percent)%")
                            }
                            else {
                                logger.logInfo("🔋 IOKit HID device [\(deviceClass)]: \(name) - \(percent)%")
                            }
                            let profile = AppDeviceProfileObject(model: model, vendor: vendor, serial: serial, hardware: nil, apperance: nil, findmy: false)
                            self.bluetoothSaveDeviceAndBattery(name: name, identifier: stableID, battery: percent, profile: profile, address: address)
                            classDeviceCount += 1
                            totalDevicesFound += 1
                        }

                        IOObjectRelease(object)
                    }
                } while object != 0

                if classDeviceCount > 0 {
                    logger.logDebug("Found \(classDeviceCount) devices in class \(deviceClass)")
                }
                IOObjectRelease(iterator)
            }
            else {
                logger.logError("Failed to get matching services for \(deviceClass): \(result)")
            }
        }

        if totalDevicesFound == 0 {
            logger.logDebug("No IOKit HID devices with battery found")
        }
        else {
            logger.logInfo("IOKit HID scan completed: \(totalDevicesFound) devices total")
        }
    }

    private func bluetoothGetIOKitBatteryLevel(deviceName: String) -> Int? {
        let deviceClasses = ["AppleBluetoothHIDKeyboard", "BNBMouseDevice", "AppleDeviceManagementHIDEventService"]

        for deviceClass in deviceClasses {
            var iterator = io_iterator_t()
            var object = io_object_t()
            let port: mach_port_t = kIOMainPortDefault

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

    static func bluetoothParseContinuityManufacturerData(_ data: Data) -> ContinuityMessageResult? {
        guard data.count >= 2 else {
            return nil
        }

        let companyID = UInt16(data[0]) | (UInt16(data[1]) << 8)
        guard companyID == 0x004C else {
            return nil
        }

        var offset = 2
        var results: [ContinuityMessageResult] = []

        while offset < data.count {
            guard offset + 1 < data.count else {
                break
            }

            let type = data[offset]
            let length = Int(data[offset + 1])

            guard offset + 2 + length <= data.count else {
                break
            }

            let result: ContinuityMessageResult?
            switch type {
                case 0x07: result = bluetoothParseContinuityType07(data, offset: offset, length: length)
                case 0x0C: result = bluetoothParseContinuityType0C(data, offset: offset, length: length)
                case 0x10: result = bluetoothParseContinuityType10(data, offset: offset, length: length)
                default: result = nil
            }

            if let result = result {
                results.append(result)
            }

            offset += 2 + length
        }

        return results.first(where: { $0.batteryLevel != nil })
    }

    internal static func bluetoothValidateBatteryValue(_ value: UInt8) -> Int? {
        guard value > 0 && value <= 100 else {
            return nil
        }

        return Int(value)
    }

    private static func bluetoothParseContinuityType07(_ data: Data, offset: Int, length: Int) -> ContinuityMessageResult? {
        guard length >= 25 else {
            return nil
        }

        let batteryLeft = data[offset + 13]
        let batteryRight = data[offset + 14]
        let batteryEnclosure = data[offset + 15]

        let validatedLeft = bluetoothValidateBatteryValue(batteryLeft)
        let validatedRight = bluetoothValidateBatteryValue(batteryRight)
        let validatedEnclosure = bluetoothValidateBatteryValue(batteryEnclosure)

        let batteries = [validatedLeft, validatedRight, validatedEnclosure].compactMap { $0 }
        guard batteries.isEmpty == false else {
            return nil
        }

        let components = ContinuityBatteryComponents(left: validatedLeft, right: validatedRight, enclosure: validatedEnclosure, main: nil)

        return ContinuityMessageResult(messageType: 0x07, batteryLevel: batteries.min(), batteryComponents: components, deviceInfo: ContinuityDeviceInfo(signalStrength: nil, deviceType: "AirPods/Accessory", capabilities: nil))
    }

    private static func bluetoothParseContinuityType0C(_ data: Data, offset: Int, length: Int) -> ContinuityMessageResult? {
        guard length >= 7 else {
            return nil
        }

        let batteryOffset = offset + 2 + 5
        guard batteryOffset < data.count else {
            return nil
        }

        let batteryValue = data[batteryOffset]
        let validatedBattery = bluetoothValidateBatteryValue(batteryValue)

        var signalStrength: Int? = nil
        if batteryOffset + 1 < data.count {
            let signalValue = data[batteryOffset + 1]
            if signalValue > 0 && signalValue <= 5 {
                signalStrength = Int(signalValue)
            }

        }

        let deviceInfo = ContinuityDeviceInfo(signalStrength: signalStrength, deviceType: "iPhone/iPad", capabilities: ["Hotspot", "Continuity"])

        if validatedBattery != nil {
            let components = ContinuityBatteryComponents(left: nil, right: nil, enclosure: nil, main: validatedBattery)
            return ContinuityMessageResult(messageType: 0x0C, batteryLevel: validatedBattery, batteryComponents: components, deviceInfo: deviceInfo)
        }

        else {
            return ContinuityMessageResult(messageType: 0x0C, batteryLevel: nil, batteryComponents: nil, deviceInfo: deviceInfo)
        }

    }

    private static func bluetoothParseContinuityType10(_ data: Data, offset: Int, length: Int) -> ContinuityMessageResult? {
        guard length >= 5 else {
            return nil
        }

        return nil
    }

    private func bluetoothCleanupStaleStates() {
        let activeBroadcastIDs = Set(self.broadcasting.map { $0.peripheral.identifier })
        self.peripheralStates = self.peripheralStates.filter { activeBroadcastIDs.contains($0.key) }
    }

    deinit {
        self.updates.forEach { $0.cancel() }

    }

}
