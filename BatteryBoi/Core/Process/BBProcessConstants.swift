//
//  BBProcessConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation

enum ProcessPrimaryCommands: String, CaseIterable {
    case menubar = "menubar"
    case notifications = "notify"
    case battery = "battery"
    case debug = "debug"
    case settings = "settings"
    case devices = "devices"
    case website = "website"
    case github = "github"
    case rate = "rate"
    case beta = "beta"
    case power = "power"
    case status = "status"
    case log = "log"
    case intro = "intro"
    case reset = "reset"
    case deduplicate = "deduplicate"
    case camera = "camera"

    var description: String {
        switch self {
            case .menubar: return "Settings & Customization for the Menu Bar Icon"
            case .notifications: return "Notifications Settings"
            case .battery: return "Battery Information for System & Setting Max Charge Limit"
            case .debug: return "App System Status & Debugging Information"
            case .devices: return "List & Append Device Information"
            case .settings: return "Information & Customization for Settings"
            case .website: return "Opens BatteryBoi Website"
            case .github: return "Opens BatteryBoi GitHub Repository"
            case .rate: return "Rate BatteryBoi on ProductHunt"
            case .beta: return "Enable/Disable Beta Program (Note: May Cause Crashes or Unstable Performance)"
            case .power: return "Power Mode Management & Low Power Toggle"
            case .status: return "Complete Battery Dashboard with All Information"
            case .log: return "Export & View Application Logs"
            case .intro: return "Show the Intro/Onboarding Window"
            case .reset: return "Reset Application Data"
            case .deduplicate: return "Remove Duplicate Devices & Merge Battery Events"
            case .camera: return "Camera Activity & Status Information"
        }
    }

    var secondary: [ProcessSecondaryCommands] {
        switch self {
            case .menubar: return [.info, .set, .reset]
            case .notifications: return [.info, .set, .reset]
            case .battery: return [.info, .set, .health, .thermal, .time]
            case .debug: return [.info, .reset]
            case .devices: return [.list, .reset]
            case .settings: return [.info, .set, .reset]
            case .website: return [.open]
            case .github: return [.open]
            case .rate: return [.open]
            case .beta: return [.set]
            case .power: return [.mode, .toggle]
            case .status: return [.info]
            case .log: return [.export]
            case .intro: return [.show]
            case .reset: return [.onboarding, .defaults, .database, .all]
            case .deduplicate: return []
            case .camera: return [.info]
        }
    }
}

enum ProcessSecondaryCommands: String {
    case set = "set"
    case show = "show"
    case info = "info"
    case list = "list"
    case remove = "remove"
    case recent = "recent"
    case reset = "reset"
    case open = "open"
    case health = "health"
    case thermal = "thermal"
    case time = "time"
    case mode = "mode"
    case toggle = "toggle"
    case export = "export"
    case onboarding = "onboarding"
    case defaults = "defaults"
    case database = "database"
    case all = "all"
}

enum ProcessResponseHeaderType: String {
    case normal
    case error
    case sucsess
    case warning
}

struct ProcessResponseValueObjectType {
    var value: String
    var type: ProcessResponseHeaderType

    init(_ value: String?, type: ProcessResponseHeaderType = .normal, placeholder: Bool = true) {
        switch placeholder {
            case true: self.value = value ?? "PermissionsUnknownLabel".localise()
            case false: self.value = value ?? ""
        }

        self.type = type
    }
}

enum ProcessPermissionState: String {
    case error
    case allowed
    case undetermined
    case denied
    case unknown

    var title: String {
        switch self {
            case .error: return "PermissionsErrorLabel".localise(["pissnugget"])
            case .allowed: return "PermissionsEnabledLabel".localise()
            case .undetermined: return "PermissionsUndeterminedLabel".localise()
            case .denied: return "PermissionsDeniedLabel".localise()
            case .unknown: return "PermissionsUnknownLabel".localise()
        }
    }

    var flag: Bool {
        switch self {
            case .allowed: return true
            case .unknown: return true
            default: return false
        }
    }
}

enum ProcessHomebrewState: String {
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
