//
//  BBCloudConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation
import CloudKit
import CoreData

public enum CloudEntityType: String {
    case devices = "Devices"
    case events = "Events"
}

public enum CloudNotificationType: String {
    case alert
    case background
    case none
}

public enum CloudState: String {
    case unknown
    case enabled
    case blocked
    case disabled

    var title: String {
        switch self {
            case .enabled: return "PermissionsEnabledLabel".localise()
            case .blocked: return "PermissionsBlockedLabel".localise()
            case .disabled: return "PermissionsDisabledLabel".localise()
            case .unknown: return "PermissionsUnknownLabel".localise()
        }
    }
}

public enum CloudSyncedState: String {
    case syncing
    case completed
    case error
}

public struct CloudContainerObject {
    var container: NSPersistentCloudKitContainer?
    var directory: URL?
    var parent: URL?
    var storage: Any?
}

public enum CloudSubscriptionsType: String {
    case alerts
    case events
    case device

    var identifyer: String {
        switch self {
            case .alerts: return "sub.alert"
            case .events: return "sub.event"
            case .device: return "sub.device"
        }
    }

    var record: String {
        switch self {
            case .alerts: return "CD_Alerts"
            case .device: return "CD_Devices"
            case .events: return "CD_Battery"
        }
    }

    var options: CKQuerySubscription.Options {
        switch self {
            case .device: return .firesOnRecordCreation
            case .events: return .firesOnRecordCreation
            case .alerts: return .firesOnRecordCreation
        }
    }
}
