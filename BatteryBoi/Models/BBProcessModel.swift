//
//  ProcessModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/4/23.
//

import Foundation

enum ProcessPrimaryCommands:String,CaseIterable {
    case menubar = "mbar"
    case battery = "batt"
    case debug = "debug"
    case settings = "settings"
    case devices = "devices"
    case website = "website"
    case rate = "rate"

    var description:String {
        switch self {
            case .menubar : return "Settings & Customization for the Menu Bar Icon"
            case .battery : return "Battery Information for System & Setting Max Charge Limit"
            case .debug : return "App System Status & Debugging Information"
            case .devices : return "List & Append Device Information"
            case .settings : return "Information & Customization for Settings"
            case .website : return "Opens BatteryBoi Website"
            case .rate : return "Rate BatteryBoi on ProductHunt"

        }
        
    }
    
    var secondary:[ProcessSecondaryCommands] {
        switch self {
            case .menubar : return [.info, .set, .reset]
            case .battery : return [.info]
            case .debug : return [.info, .reset]
            case .devices : return [.list, .reset]
            case .settings : return [.info, .set, .reset]
            case .website : return [.open]
            case .rate : return [.open]

        }
        
    }
    
}

enum ProcessSecondaryCommands:String {
    case set = "set"
    case show = "show"
    case info = "info"
    case list = "list"
    case remove = "remove"
    case recent = "recent"
    case reset = "reset"
    case open = "open"
    
}

enum ProcessResponseHeaderType:String {
    case normal
    case error
    case sucsess
    
}

enum ProcessPermissionState:String {
    case error
    case allowed
    case undetermined
    case denied
    case unknown
    
    var title:String {
        switch self {
            case .error : return "PermissionsErrorLabel".localise(["pissnugget"])
            case .allowed : return "PermissionsEnabledLabel".localise()
            case .undetermined : return "PermissionsUndeterminedLabel".localise()
            case .denied : return "PermissionsDeniedLabel".localise()
            case .unknown : return "PermissionsUnknownLabel".localise()

        }
        
    }
    
}

enum ProcessHomebrewState:String {
    case installed
    case unknown
    case notfound
    
}

enum ProcessState {
    case idle
    case waiting
    case failed
    case complete
    
}
