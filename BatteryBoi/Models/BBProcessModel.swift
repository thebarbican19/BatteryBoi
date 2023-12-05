//
//  ProcessModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/4/23.
//

import Foundation

enum ProcessPrimaryCommands:String {
    case menubar = "mbar"
    case battery = "batt"
    case alert = "alert"
    case debug = "debug"
    case devices = "devices"
    case website = "website"

    var description:String {
        switch self {
            case .menubar : return "Settings & Customization for the Menu Bar Icon"
            case .battery : return "Battery Information for System & Setting Max Charge Limit"
            case .alert : return "Settings & Customization for Alert View"
            case .debug : return "App System Status & Debugging Information"
            case .devices : return "List & Append Device Information"
            case .website : return "Opens BatteryBoi Website"
            
        }
        
    }
    
    var secondary:[ProcessSecondaryCommands] {
        switch self {
            case .menubar : return [.help, .info, .set]
            case .battery : return [.info, .help, .set]
            case .alert : return [.help, .set, .show]
            case .debug : return [.info, .reset]
            case .devices : return [.list, .help, .remove, .reset]
            case .website : return [.open]
            
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
    case help = "help"
    case open = "open"
    
}

enum ProcessResponseHeaderType:String {
    case normal
    case error
    case sucsess
    
}

enum ProcessPermissionState:String {
    case allowed
    case undetermined
    case denied
    case unknown
    
}

enum ProcessState {
    case idle
    case waiting
    case failed
    case complete
    
}
