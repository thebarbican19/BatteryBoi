//
//  BBSystemModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/21/23.
//

import Foundation
import AVFoundation
import Foundation
import CloudKit
import CoreData

#if os(macOS)
    import AppKit

#elseif os(iOS)
    import UIKit

#endif

public enum SystemDistribution {
    case direct
    case appstore
    
}

public struct SystemProfileObject:Codable {
    var id:String
    var display:String
    
}

public enum SystemMenuView:String {
    case settings
    case stats
    case devices
    
}

public struct SystemAppUsage {
    var day:Int
    var timestamp:Date
    
}

public enum SystemSoundEffects:String {
    case high = "highnote"
    case low = "lownote"
  
    public func play(_ force:Bool = false) {
        if SettingsManager.shared.enabledSoundEffects == .enabled || force == true {
            #if os(macOS)
                NSSound(named: self.rawValue)?.play()
            
            #elseif os(iOS)
                if let path = Bundle.main.url(forResource: self.rawValue, withExtension: "wav") {
                    _ = try? AVAudioPlayer(contentsOf: path).play()
                    
                }
            
            #endif

        }
        
    }
    
}

enum SystemDeviceCategory:String,Codable {
    case desktop
    case laptop
    case tablet
    case smartphone
    
}

enum SystemDeviceTypes:String,Codable {
    case macbook
    case macbookPro
    case macbookAir
    case imac
    case macMini
    case macPro
    case macStudio
    case ipad
    case iphone
    case unknown
    
    func name(_ alias:Bool = true) -> String {
        if alias == true {
            #if os(macOS)
                if let name = Host.current().localizedName {
                    return name
                    
                }
            
            #elseif os(iOS)
                return UIDevice.current.name
            
            #endif
            
        }
        
        switch self {
            case .macbook: return "Macbook"
            case .macbookPro: return "Macbook Pro"
            case .macbookAir: return "Macbook Air"
            case .imac: return "iMac"
            case .ipad: return "iPad"
            case .iphone: return "iPhone"
            case .macMini: return "Mac Mini"
            case .macPro: return "Mac Pro"
            case .macStudio: return "Mac Pro"
            case .unknown: return "AlertDeviceUnknownTitle".localise()
            
        }
        
    }
    
    var battery:Bool {
        switch self {
            case .macbook: return true
            case .macbookPro: return true
            case .macbookAir: return true
            case .ipad: return true
            case .iphone: return true
            case .imac: return false
            case .macMini: return false
            case .macPro: return false
            case .macStudio: return false
            case .unknown: return false
            
        }
        
    }
    
    var category:SystemDeviceCategory {
        switch self {
            case .macbook: return .laptop
            case .macbookPro: return .laptop
            case .macbookAir: return .laptop
            case .imac: return .desktop
            case .macMini: return .desktop
            case .macPro: return .desktop
            case .macStudio: return .desktop
            case .ipad: return .tablet
            case .iphone: return .smartphone
            case .unknown: return .desktop
            
        }
        
    }
    
    var icon:String {
        switch self {
            case .imac: return "desktopcomputer"
            case .macMini: return "macmini"
            case .macPro: return "macpro.gen3"
            case .macStudio: return "macstudio"
            default : return "laptopcomputer"
            
        }
        
    }
    
}

struct SystemDeviceProfileObject {
    var serial:String?
    var hardware:String?
    
}

enum SystemConnectivityType {
    case bluetooth
    case system
    
}

struct SystemDeviceObject:Equatable {
    static func == (lhs: SystemDeviceObject, rhs: SystemDeviceObject) -> Bool {
        lhs.id == rhs.id && lhs.synced == rhs.synced && lhs.favourite == rhs.favourite
        
    }
    
    var id:UUID? = nil
    var address: String?
    var name:String
    var profile:SystemDeviceProfileObject
    var connectivity:SystemConnectivityType
    var synced:Bool
    var favourite:Bool
    var order:Int

    
}

enum SystemEvents:String {
    case fatalError = "fatal.error"
    case userInstalled = "user.installed"
    case userUpdated = "user.updated"
    case userActive = "user.active"
    case userProfile = "user.profile.detected"
    case userTerminated = "user.quit"
    case userClicked = "user.cta"
    case userPreferences = "user.preferences"
    case userLaunched = "user.launched"

}

enum SystemDefaultsKeys: String {
    case enabledAnalytics = "sd_settings_analytics"
    case enabledLogin = "sd_settings_login"
    case enabledEstimate = "sd_settings_estimate"
    case enabledBluetooth = "sd_bluetooth_state"
    case enabledDisplay = "sd_settings_display"
    case enabledStyle = "sd_settings_style"
    case enabledTheme = "sd_settings_theme"
    case enabledSoundEffects = "sd_settings_sfx"
    case enabledChargeEighty = "sd_charge_eighty"
    case enabledProgressState = "sd_progress_state"
    case enabledPinned = "sd_pinned_mode"

    case batteryUntilFull = "sd_charge_full"
    case batteryLastCharged = "sd_charge_last"
    case batteryDepletionRate = "sd_depletion_rate"
    case batteryWindowPosition = "sd_window_position"

    case versionInstalled = "sd_version_installed"
    case versionCurrent = "sd_version_current"
    case versionIdenfiyer = "sd_version_id"
    
    case usageDay = "sd_usage_days"
    case usageTimestamp = "sd_usage_date"
    
    case profileChecked = "sd_profiles_checked"
    case profilePayload = "sd_profiles_payload"

    var name:String {
        switch self {
            case .enabledAnalytics:return "Analytics"
            case .enabledLogin:return "Launch at Login"
            case .enabledEstimate:return "Battery Time Estimate"
            case .enabledBluetooth:return "Bluetooth"
            case .enabledStyle:return "Icon Style"
            case .enabledDisplay:return "Icon Display Text"
            case .enabledTheme:return "Theme"
            case .enabledSoundEffects:return "SFX"
            case .enabledChargeEighty:return "Show complete at 80%"
            case .enabledProgressState:return "Show Progress"
            case .enabledPinned:return "Pinned"

            case .batteryUntilFull:return "Seconds until Charged"
            case .batteryLastCharged:return "Seconds until Charged"
            case .batteryDepletionRate:return "Battery Depletion Rate"
            case .batteryWindowPosition:return "Battery Window Positio"
            
            case .versionInstalled:return "Installed on"
            case .versionCurrent:return "Active Version"
            case .versionIdenfiyer:return "App ID"

            case .usageDay:return "sd_usage_days"
            case .usageTimestamp:return "sd_usage_timestamp"
            
            case .profileChecked:return "Profile Validated"
            case .profilePayload:return "Profile Payload"

        }
        
    }
    
}

