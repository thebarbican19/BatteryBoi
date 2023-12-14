//
//  BBCloudModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/27/23.
//

import Foundation
import CloudKit
import CoreData

#if os(iOS)
    import ActivityKit
    import UIKit

#endif

#if os(iOS)
    struct CloudNotifyAttributes:ActivityAttributes {
        let device:String

        public struct ContentState:Hashable,Codable {
            var battery:Int
            var charging:Bool
            var timestamp:Date
            
        }

    }

#endif

enum CloudEntityType:String {
    case devices = "Devices"
    case events = "Events"
    
}

enum CloudNotificationType:String {
    case alert
    case background
    case none
    
}

enum CloudState:String {
    case unknown
    case enabled
    case blocked
    case disabled
    
    var title:String {
        switch self {
            case .enabled : return "PermissionsEnabledLabel".localise()
            case .blocked : return "PermissionsBlockedLabel".localise()
            case .disabled : return "PermissionsDisabledLabel".localise()
            case .unknown : return "PermissionsUnknownLabel".localise()

        }
        
    }
    
}

enum CloudSyncedState:String {
    case syncing
    case completed
    case error
    
}

struct CloudContainerObject {
    var container:NSPersistentCloudKitContainer?
    var directory:URL?
    var parent:URL?

}

enum CloudSubscriptionsType:String {
    case background
    case events
    case device
    
    var identifyer:String {
        switch self {
            case .background : return "new_activity"
            case .device : return "new_device"
            case .events : return "new_event"

        }
        
    }
    
    var record:String {
        switch self {
            case .device : return "CD_Devices"
            default : return "CD_Events"

        }
        
    }
    
    var options:CKQuerySubscription.Options {
        switch self {
            case .device : return .firesOnRecordCreation
            case .events : return .firesOnRecordCreation
            case .background : return .firesOnRecordCreation

        }
        
    }
    
    var background:Bool {
        switch self {
            case .device : return false
            case .events : return false
            case .background : return true
            
        }
        
    }
    
}
