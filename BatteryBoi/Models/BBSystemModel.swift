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
import CoreBluetooth

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
    
    func name(_ alias:Bool = true) -> String? {
        var name:String? = nil
        switch self {
            case .macbook: name = "Macbook"
            case .macbookPro: name = "Macbook Pro"
            case .macbookAir: name = "Macbook Air"
            case .imac: name = "iMac"
            case .ipad: name = "iPad"
            case .iphone: name = "iPhone"
            case .macMini: name = "Mac Mini"
            case .macPro: name = "Mac Pro"
            case .macStudio: name = "Mac Pro"
            case .unknown: name = "AlertDeviceUnknownTitle".localise()
            
        }
        
        if alias == true {
            #if os(macOS)
                if let name = Host.current().localizedName {
                    return name
                    
                }
            
            #elseif os(iOS)
                if UIDevice.current.name != name {
                    return UIDevice.current.name
                    
                }
                else {
                    return nil
                    
                }
            
            #endif
            
        }
        
        return nil
        
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

struct SystemDeviceProfileObject:Hashable,Equatable {
    static func == (lhs: SystemDeviceProfileObject, rhs: SystemDeviceProfileObject) -> Bool {
        lhs.serial == rhs.serial
        
    }
    
    var serial:String?
    var hardware:String?
    var vendor:String?
    
}

enum SystemConnectivityType:String {
    case bluetooth
    case system
    
}

struct SystemEventObject:Identifiable,Hashable {
    static func == (lhs: SystemEventObject, rhs: SystemEventObject) -> Bool {
        lhs.id == rhs.id

    }
    
    var id:UUID
    var created:Date = Date()
    var state:StatsStateType?
    var battery:Int
    
    init?(_ event:Events?) {
        if let id = event?.id, let state = StatsStateType(rawValue: event?.state ?? ""), let timestamp = event?.timestamp {
            self.id = id
            self.state = state
            self.created = timestamp
            self.battery = Int(event?.charge ?? 100)
            
        }
        else {
            return nil
            
        }
        
    }

}

struct SystemDeviceObject:Hashable,Equatable,Identifiable {
    static func == (lhs: SystemDeviceObject, rhs: SystemDeviceObject) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
        
    }
    
    var id:UUID
    var address: String?
    var name:String
    var profile:SystemDeviceProfileObject?
    var connectivity:SystemConnectivityType = .system
    var polled:Date? = nil
    var synced:Bool = true
    var favourite:Bool = false
    var notifications:Bool = true
    var order:Int = 1
    var distance:SystemDeviceDistanceObject? = nil
    var events:[SystemEventObject] = []
    
    init?(_ device:Devices) {
        if let id = device.id, let events = device.events?.allObjects {
            self.id = id
            self.name = device.name ?? device.match ?? "Shiittt"
            self.profile = .init(serial:device.serial, vendor: device.vendor)
            self.synced = true
            self.favourite = device.favourite
            self.notifications = device.notifications
            self.order = Int(device.order)
            self.distance = nil
            self.events = events.compactMap({ SystemEventObject.init($0 as? Events) }).sorted(by: { $0.created > $1.created })
            self.polled = self.events.first?.created ?? nil
            
            if UUID.device() == id {
                self.connectivity = .system

            }
            else {
                self.connectivity = .bluetooth

            }

            print("\(name) has \(events.count) events")
            print("\(name) set events \(self.events.count)")

        }
        else {
            return nil
            
        }
 
    }
    
    init(_ id:UUID, name:String, profile:SystemDeviceProfileObject, connectivity:SystemConnectivityType = .bluetooth, synced:Bool = false, distance:SystemDeviceDistanceObject? = nil) {
        self.id = id
        self.name = name
        self.address = ""
        self.profile = profile
        self.connectivity = connectivity
        self.synced = synced
        self.order = 0
        self.favourite = false
        self.notifications = true
        self.polled = nil
        self.distance = distance
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        
    }
    
}

enum SystemDeviceDistanceType:Int {
    case unknown = 0
    case proximate = 1
    case near = 2
    case far = 3
    
    var string:String? {
        switch self {
            case .unknown : return nil
            case .proximate : return "BluetoothDistanceProximateLabel".localise()
            case .near : return "BluetoothDistanceNearLabel".localise()
            case .far : return "BluetoothDistanceFarLabel".localise()

        }
        
    }
    
}

struct SystemDeviceDistanceObject:Equatable {
    var value:Double
    var state:SystemDeviceDistanceType
    
    init(_ value: Double) {
        if value >= -50 && value <= -20 {
            self.state = .proximate

        }
        else if value >= -70 && value < -50 {
            self.state = .near

        }
        else {
            self.state = .far

        }
            
        self.value = value
        
    }
    
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
    
    case onboardingIntro = "sd_onboarding_intro"

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

            case .onboardingIntro:return "Onboarding Intro"

        }
        
    }
    
}

