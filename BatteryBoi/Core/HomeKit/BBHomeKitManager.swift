//
//  BBHomeKitManager.swift
//  BatteryBoi
//
//  Created by Claude Sonnet 4.5 on 12/31/25.
//

import Foundation
import Combine
import HomeKit
import UIKit

public class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryDelegate {
    @Published var state: AppAuthorizationState = .unknown
    @Published var accessories: [HomeKitAccessoryItem] = []
    @Published var homes: [HMHome] = []

    private var manager: HMHomeManager?
    private var updates = Set<AnyCancellable>()

    static var shared = HomeKitManager()
    private let logger = LogManager.shared

    override init() {
        super.init()

        logger.logInfo("Initializing HomeKitManager")

        if UserDefaults.main.object(forKey: AppDefaultsKeys.homekitEnabled.rawValue) == nil {
            self.homekitAuthorization()
        }

        else {
            logger.logWarning("HomeKit disabled by user")
        }

        Timer.publish(every: 300, on: .main, in: .common).autoconnect().sink { _ in
            self.homekitRefreshAccessories()

        }.store(in: &updates)

        $state.removeDuplicates().receive(on: DispatchQueue.main).sink { state in
            self.logger.logInfo("HomeKit state changed to: \(state.rawValue)")
            if state == .denied || state == .restricted {
                UserDefaults.save(.homekitEnabled, value: state.rawValue)
                self.accessories = []
            }

            else if state == .allowed {
                UserDefaults.save(.homekitEnabled, value: nil)
                self.homekitInitializeManager()
            }

        }.store(in: &updates)

        $accessories.debounce(for: .seconds(2), scheduler: RunLoop.main).receive(on: DispatchQueue.main).sink { items in
            for item in items.filter({ $0.state == .available && $0.batteryLevel != nil }) {
                self.logger.logInfo("Processing accessory: \(item.accessory.name) - \(item.batteryLevel ?? 0)%")
            }

        }.store(in: &updates)

        NotificationCenter.default.addObserver(self, selector: #selector(homekitRecheckAuthorization), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    deinit {
        self.updates.forEach { $0.cancel() }
    }

    public func homekitAuthorization(_ force: Bool = false) {
        if UserDefaults.main.object(forKey: AppDefaultsKeys.homekitEnabled.rawValue) == nil {
            if force == true {
                self.homekitInitializeManager()
            }

            else {
                if let manager = self.manager {
                    self.homekitAuthorizationState()
                }

            }

            DispatchQueue.main.async {
                self.homekitAuthorizationState()
            }

        }

    }

    public func homekitAuthorizationState() {
        guard let manager = self.manager else {
            self.state = .undetermined
            return
        }

        let status = manager.authorizationStatus

        if status.contains(.authorized) {
            self.state = .allowed
        }

        else if status.contains(.restricted) {
            self.state = .restricted
        }

        else if status.contains(.determined) {
            self.state = .denied
        }

        else {
            self.state = .undetermined
        }

    }

    @objc private func homekitRecheckAuthorization() {
        self.homekitAuthorization()
    }

    private func homekitInitializeManager() {
        if self.manager == nil {
            logger.logInfo("Initializing HMHomeManager")
            self.manager = HMHomeManager()
            self.manager?.delegate = self
        }

    }

    public func homekitRefreshAccessories() {
        guard let manager = self.manager else {
            logger.logWarning("Cannot refresh accessories - manager not initialized")
            return
        }

        logger.logDebug("Refreshing HomeKit accessories")

        for home in manager.homes {
            for accessory in home.accessories {
                self.homekitProcessAccessory(accessory)
            }

        }

    }

    private func homekitProcessAccessory(_ accessory: HMAccessory) {
        logger.logDebug("Processing accessory: \(accessory.name) (Reachable: \(accessory.isReachable))")

        accessory.delegate = self

        if let batteryService = accessory.services.first(where: { $0.serviceType == HMServiceTypeBattery }) {
            self.homekitReadBatteryLevel(for: accessory, service: batteryService)
        }

        else {
            logger.logDebug("No battery service found for \(accessory.name)")
        }

        self.homekitUpdateAccessoryList(accessory)
    }

    private func homekitReadBatteryLevel(for accessory: HMAccessory, service: HMService) {
        guard let batteryLevelChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBatteryLevel }) else {
            logger.logDebug("No battery level characteristic for \(accessory.name)")
            return
        }

        batteryLevelChar.readValue { [weak self] error in
            if let error = error {
                self?.logger.logError("Failed to read battery for \(accessory.name): \(error.localizedDescription)")
                return
            }

            if let level = batteryLevelChar.value as? Int {
                self?.logger.logInfo("Battery level for \(accessory.name): \(level)%")
                self?.homekitProcessBatteryLevel(level, for: accessory)
            }

        }

        self.homekitEnableNotifications(for: accessory)
    }

    private func homekitProcessBatteryLevel(_ level: Int, for accessory: HMAccessory) {
        let model = accessory.model ?? "HomeKit Accessory"
        let vendor = accessory.manufacturer

        let profile = AppDeviceProfileObject(model: model, vendor: vendor, serial: nil, hardware: nil, apperance: nil, findmy: false)

        self.homekitSaveDeviceAndBattery(name: accessory.name, identifier: accessory.uniqueIdentifier, battery: level, profile: profile)
    }

    private func homekitUpdateAccessoryList(_ accessory: HMAccessory) {
        DispatchQueue.main.async {
            if let index = self.accessories.firstIndex(where: { $0.id == accessory.uniqueIdentifier }) {
                var item = self.accessories[index]
                item.state = accessory.isReachable ? .available : .unavailable
                item.lastUpdated = Date()
                self.accessories[index] = item
            }

            else {
                let newItem = HomeKitAccessoryItem(accessory)
                self.accessories.append(newItem)
            }

        }

    }

    private func homekitSaveDeviceAndBattery(name: String, identifier: UUID, battery: Int, profile: AppDeviceProfileObject) {
        if let context = AppManager.shared.appStorageContext() {
            let tempDevice = AppDeviceObject(identifier, name: name, profile: profile)

            if let match = AppDeviceObject.match(tempDevice, context: context) {
                logger.logInfo("📊 Saving battery event for existing HomeKit device: \(name) (\(battery)%)")
                AppManager.shared.appStoreDevice(match)
                BatteryManager.shared.powerStoreEvent(match, battery: battery)
            }

            else {
                logger.logInfo("📊 Creating new HomeKit device and battery event: \(name) (\(battery)%)")
                AppManager.shared.appStoreDevice(tempDevice)
                BatteryManager.shared.powerStoreEvent(tempDevice, battery: battery)
            }

        }

        else {
            logger.logError("Cannot save HomeKit device - SwiftData context unavailable")
        }

    }

    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        logger.logInfo("Home manager updated homes - count: \(manager.homes.count)")

        DispatchQueue.main.async {
            self.homes = manager.homes
            self.homekitAuthorizationState()
            self.homekitRefreshAccessories()
        }

    }

    public func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        logger.logInfo("Primary home updated")
        self.homekitRefreshAccessories()
    }

    public func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        logger.logInfo("Accessory reachability changed: \(accessory.name) - \(accessory.isReachable)")
        self.homekitUpdateAccessoryList(accessory)

        if accessory.isReachable {
            self.homekitProcessAccessory(accessory)
        }

    }

    public func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        if characteristic.characteristicType == HMCharacteristicTypeBatteryLevel {
            if let level = characteristic.value as? Int {
                logger.logInfo("Battery characteristic updated for \(accessory.name): \(level)%")
                self.homekitProcessBatteryLevel(level, for: accessory)
            }

        }

    }

    private func homekitMatchAccessory(_ accessory: HMAccessory) -> AppDeviceObject? {
        guard let index = self.accessories.firstIndex(where: { $0.accessory.uniqueIdentifier == accessory.uniqueIdentifier }) else {
            return nil
        }

        let item = self.accessories[index]

        if let batteryLevel = item.batteryLevel {
            let profile = AppDeviceProfileObject(model: accessory.model ?? "HomeKit Accessory", vendor: accessory.manufacturer, serial: nil, hardware: nil, apperance: nil, findmy: false)

            return AppDeviceObject(accessory.uniqueIdentifier, name: accessory.name, profile: profile)
        }

        return nil
    }

    private func homekitEnableNotifications(for accessory: HMAccessory) {
        guard let batteryService = accessory.services.first(where: { $0.serviceType == HMServiceTypeBattery }) else {
            return
        }

        if let batteryLevelChar = batteryService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBatteryLevel }) {
            batteryLevelChar.enableNotification(true) { error in
                if let error = error {
                    self.logger.logError("Failed to enable notifications for \(accessory.name): \(error.localizedDescription)")
                }

                else {
                    self.logger.logDebug("Enabled battery notifications for \(accessory.name)")
                }

            }

        }

    }

}
