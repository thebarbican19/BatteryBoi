//
//  BBHomeKitManager.swift
//  BatteryBoi
//
//  Created by Gemini on 12/30/25.
//

import Foundation
import Combine
import HomeKit

public class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate {
    static let shared = HomeKitManager()

    private var manager: HMHomeManager?

    @Published var state: AppAuthorizationState = .unknown

    override init() {
        super.init()
//        if UserDefaults.main.object(forKey: AppDefaultsKeys.homeKitEnabled.rawValue) != nil {
//             self.requestAuthorization()
//        }
//        else {
//
//        }

        self.state = .undetermined
    }

    public func requestAuthorization() {
        if self.manager == nil {
            self.manager = HMHomeManager()
            self.manager?.delegate = self

        }
    }

    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        self.updateAuthorizationState()
        self.fetchHomeKitAccessories()
    }

    public func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        self.fetchHomeKitAccessories()
    }

    public func homeKitAuthorizationState() {
        guard let manager = self.manager else {
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

    private func updateAuthorizationState() {
        DispatchQueue.main.async {
            self.homeKitAuthorizationState()

        }

    }

    public func fetchHomeKitAccessories() {
        guard let manager = self.manager else {
            return

        }

        for home in manager.homes {
            for accessory in home.accessories {
                self.homekitAccessoryBatteryState(for: accessory)

            }

        }

    }

    private func homekitAccessoryBatteryState(for accessory: HMAccessory) {
        guard let batteryService = accessory.services.first(where: { $0.serviceType == HMServiceTypeBattery }) else {
            return
        }

        guard let batteryLevelChar = batteryService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBatteryLevel }) else {
            return
        }

        batteryLevelChar.readValue { [weak self] error in
            if error != nil {
                return
            }

            if let level = batteryLevelChar.value as? Int {
                self?.processBatteryLevel(level, for: accessory)

            }

        }

    }

    private func processBatteryLevel(_ level: Int, for accessory: HMAccessory) {
        let model = accessory.model ?? "HomeKit Device"
        let vendor = accessory.manufacturer

        let profile = AppDeviceProfileObject(
            model: model,
            vendor: vendor,
            serial: nil,
            hardware: nil,
            apperance: nil,
            findmy: false
        )

        self.saveDeviceAndBattery(name: accessory.name, identifier: accessory.uniqueIdentifier, battery: level, profile: profile)
    }

    private func saveDeviceAndBattery(name: String, identifier: UUID, battery: Int, profile: AppDeviceProfileObject) {
        if let context = AppManager.shared.appStorageContext() {
            let tempDevice = AppDeviceObject(identifier, name: name, profile: profile)
            if let match = AppDeviceObject.match(tempDevice, context: context) {
                AppManager.shared.appStoreDevice(match)
                BatteryManager.shared.powerStoreEvent(match, battery: battery)
            }
            else {
                AppManager.shared.appStoreDevice(tempDevice)
                BatteryManager.shared.powerStoreEvent(tempDevice, battery: battery)

            }

        }

    }

}
