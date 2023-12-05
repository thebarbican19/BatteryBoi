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
    case events
    case device
    case alert
    
    var identifyer:String {
        switch self {
            case .device : return "update_device"
            case .events : return "updated_event"
            case .alert : return "update_device"

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
            case .device : return .firesOnRecordUpdate
            case .events : return .firesOnRecordCreation
            case .alert : return .firesOnRecordCreation

        }
        
    }
    
    var background:Bool {
        switch self {
            case .device : return true
            case .events : return true
            case .alert : return false
            
        }
        
    }
    
}
