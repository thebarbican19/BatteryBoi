//
//  BBHomeKitConstants.swift
//  BatteryBoi
//
//  Created by Claude Sonnet 4.5 on 12/31/25.
//

import Foundation
import HomeKit

public enum HomeKitConnectionState: String {
    case available
    case unavailable
    case updating
    case error
}

public struct HomeKitAccessoryItem: Identifiable, Equatable {
    public static func == (lhs: HomeKitAccessoryItem, rhs: HomeKitAccessoryItem) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state && lhs.batteryLevel == rhs.batteryLevel
    }

	public var id: UUID
    var accessory: HMAccessory
    var state: HomeKitConnectionState
    var batteryLevel: Int?
    var lastUpdated: Date
    var services: [HMService]

    init(_ accessory: HMAccessory, state: HomeKitConnectionState = .available) {
        self.accessory = accessory
        self.state = state
        self.id = accessory.uniqueIdentifier
        self.batteryLevel = nil
        self.lastUpdated = Date()
        self.services = accessory.services

        if accessory.isReachable == false {
            self.state = .unavailable
        }

        else {
            self.state = state
        }

    }

}

public enum HomeKitServiceType: String, CaseIterable {
    case battery = "00000096-0000-1000-8000-0026BB765291"
    case batteryLevel = "00000068-0000-1000-8000-0026BB765291"
    case chargingState = "0000008F-0000-1000-8000-0026BB765291"
    case statusLowBattery = "00000079-0000-1000-8000-0026BB765291"

    public var type: String {
        switch self {
            case .battery: return "Battery Service"
            case .batteryLevel: return "Battery Level"
            case .chargingState: return "Charging State"
            case .statusLowBattery: return "Low Battery Status"
			
        }
		
    }

    public var hmType: String {
        switch self {
            case .battery: return HMServiceTypeBattery
            case .batteryLevel: return HMCharacteristicTypeBatteryLevel
            case .chargingState: return HMCharacteristicTypeChargingState
            case .statusLowBattery: return HMCharacteristicTypeStatusLowBattery
			
        }
		
    }

}
