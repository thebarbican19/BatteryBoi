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

enum SystemAlertTypes:Int {
    case chargingComplete
    case chargingBegan
    case chargingStopped
    case percentFive
    case percentTen
    case percentTwentyFive
    case percentOne
    case userInitiated
    case userLaunched
    case userEvent
    case deviceOverheating
    case deviceConnected
    case deviceRemoved
    case deviceDistance

    var sfx:SystemSoundEffects? {
        switch self {
            case .chargingBegan : return .high
            case .chargingComplete : return .high
            case .chargingStopped : return .low
            case .percentTwentyFive : return .low
            case .percentTen : return .low
            case .percentFive : return .low
            case .percentOne : return .low
            case .userLaunched : return nil
            case .userInitiated : return nil
            case .userEvent : return .low
            case .deviceOverheating : return .low
            case .deviceRemoved : return .low
            case .deviceConnected : return .high
            case .deviceDistance : return .low

        }
        
    }
    
    var trigger:Bool {
        switch self {
            case .chargingBegan : return true
            case .chargingComplete : return true
            case .chargingStopped : return true
            case .deviceRemoved : return true
            case .deviceConnected : return true
            default : return false
            
        }
        
    }
    
    var timeout:Bool {
        switch self {
            case .userLaunched : return false
            case .userInitiated : return false
            default : return true
            
        }
        
    }
    
}

enum SystemAlertState:Equatable {
    case hidden
    case progress
    case revealed
    case detailed
    case dismissed
    
    var visible:Bool {
        switch self {
            case .detailed : return true
            case .revealed : return true
            default : return false
            
        }
        
    }
    
    var mask:AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.6, delay: 0.2, easing: .bounce, width: 120, height: 120, blur: 0, radius: 66),
                .init(2.9, easing: .bounce, width: 430, height: 120, blur: 0, radius: 66)], id: "initial")
            
        }
        else if self == .detailed {
            return .init([.init(0.0, easing: .bounce, width: 440, height: 220, radius: 42)], id:"expand_out")
            
        }
        else if self == .dismissed {
            return .init([
                .init(0.2, easing: .bounce, width: 430, height: 120, radius: 66),
                .init(0.2, easing: .easeout, width: 120, height: 120, radius: 66),
                .init(0.3, delay:1.0, easing: .bounce, width: 40, height: 40, opacity: 0, radius: 66)], id: "expand_close")

        }
        
        return nil
        
    }
    
    var glow:AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.03, easing: .easeout, opacity: 0.0, scale: 0.2),
                .init(0.4, easing: .bounce, opacity: 0.4, scale: 1.9),
                .init(0.4, easing: .easein, opacity: 0.0, blur:2.0)])
            
        }
        else if self == .dismissed {
            return .init([
                .init(0.03, easing: .easeout, opacity: 0.0, scale: 0.2),
                .init(0.4, easing: .easein, opacity: 0.6, scale:1.4),
                .init(0.2, easing: .bounce, opacity: 0.0, scale: 0.2)])
            
        }
        
        return nil

    }
    
    var progress:AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.2, easing: .bounce, opacity: 0.0, blur:0.0, scale: 0.8),
                .init(0.4, delay: 0.4, easing: .easeout, opacity: 1.0, scale:1.0)])
            
        }
        else if self == .dismissed {
            return .init([.init(0.6, easing: .bounce, opacity: 0.0, blur:12.0, scale: 0.9)])
            
        }

        return nil
        
    }
    
    var container:AnimationObject? {
        if self == .detailed {
            return .init([.init(0.4, easing: .easeout, padding:.init(top:24, bottom:16))], id:"hud_expand")
            
        }
        else if self == .dismissed {
            return .init([.init(0.6, delay: 0.2, easing: .easeout, opacity: 0.0, blur: 5.0)])

        }
        
        return nil

    }


}


public enum SystemDistribution {
    case direct
    case appstore
    
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
    
    var mac:Bool {
        switch self {
            case .macbook: return true
            case .macbookPro: return true
            case .macbookAir: return true
            case .ipad: return false
            case .iphone: return false
            case .imac: return true
            case .macMini: return true
            case .macPro: return true
            case .macStudio: return true
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
    
    var id:String
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
    var added:Date? = nil
    
    init?(_ device:Devices) {
        if let id = device.id, let events = device.events?.allObjects {
            self.id = id
            self.name = device.name ?? id
            self.profile = .init(serial:device.serial, vendor: device.vendor)
            self.synced = true
            self.favourite = device.favourite
            self.notifications = device.notifications
            self.order = Int(device.order)
            self.distance = nil
            self.events = events.compactMap({ SystemEventObject.init($0 as? Events) }).sorted(by: { $0.created > $1.created })
            self.added = device.added_on ?? Date()
            self.polled = self.events.first?.created ?? nil
            
//            if UUID.device() == id {
//                self.connectivity = .system
//
//            }
//            else {
//                self.connectivity = .bluetooth
//
//            }

            print("\(name) has \(events.count) events")
            print("\(name) set events \(self.events.count)")

        }
        else {
            return nil
            
        }
 
    }
    
    init(_ id:String, name:String, profile:SystemDeviceProfileObject, connectivity:SystemConnectivityType = .bluetooth, synced:Bool = false, distance:SystemDeviceDistanceObject? = nil) {
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
    case enabledAnalytics = "bb_settings_analytics"
    case enabledLogin = "bb_settings_login"
    case enabledTheme = "bb_settings_theme"
    case enabledSoundEffects = "bb_settings_sfx"
    case enabledPinned = "bb_pinned_mode"

    case batteryUntilFull = "bb_charge_full"
    case batteryLastCharged = "bb_charge_last"
    case batteryDepletionRate = "bb_depletion_rate"
    case batteryWindowPosition = "bb_window_position"

    case versionInstalled = "bb_version_installed"
    case versionCurrent = "bb_version_current"
    case versionIdenfiyer = "bb_version_id"
    
    case usageDay = "bb_usage_days"
    case usageTimestamp = "bb_usage_date"
    
    case menubarStyle = "bb_mbar_style"
    case menubarRadius = "bb_mbar_radius"
    case menubarAnimation = "bb_mbar_animations"
    case menubarProgress = "bb_mbar_progress"
    case menubarPrimary = "bb_mbar_primary"
    case menubarSecondary = "bb_mbar_secondary"
    
    case bluetoothUpdated = "bb_bluetoothlte_updated"
    case bluetoothEnabled = "bb_bluetoothlte_enabled"

    case onboardingStep = "bb_onboarding_step"
    case onboardingComplete = "bb_onboarding_updated"

    var name:String {
        switch self {
            case .enabledAnalytics:return "Analytics"
            case .enabledLogin:return "Launch at Login"
            case .enabledTheme:return "Theme"
            case .enabledSoundEffects:return "SFX"
            case .enabledPinned:return "Pinned"

            case .batteryUntilFull:return "Seconds until Charged"
            case .batteryLastCharged:return "Seconds until Charged"
            case .batteryDepletionRate:return "Battery Depletion Rate"
            case .batteryWindowPosition:return "Battery Window Positio"
            
            case .versionInstalled:return "Installed on"
            case .versionCurrent:return "Active Version"
            case .versionIdenfiyer:return "App ID"

            case .usageDay:return "bb_usage_days"
            case .usageTimestamp:return "bb_usage_timestamp"
            
            case .menubarStyle:return "MenuBar Style"
            case .menubarRadius:return "MenuBar Radius"
            case .menubarPrimary:return "MenuBar Primary Display"
            case .menubarSecondary:return "MenuBar Secondary Display"
            case .menubarAnimation:return "MenuBar Pulsing Animation"
            case .menubarProgress:return "MenuBar Show Progress"
            
            case .onboardingStep:return "Onboarding Step"
            case .onboardingComplete:return "Onboarding Complete"
            
            case .bluetoothEnabled:return "Bluetooth State"
            case .bluetoothUpdated:return "Bluetooth Updated"

        }
        
    }
    
}

