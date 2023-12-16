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
    import IOKit

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
    case mouse
    case headphones
    case gamepad
    case speaker
    case keyboard
    case other
    
    var name:String {
        switch self {
            case .mouse:return "BluetoothDeviceMouseLabel".localise()
            case .headphones:return "BluetoothDeviceHeadphonesLabel".localise()
            case .gamepad:return "BluetoothDeviceGamepadLabel".localise()
            case .speaker:return "BluetoothDeviceSpeakerLabel".localise()
            case .keyboard:return "BluetoothDeviceKeyboardLabel".localise()
            case .other:return "BluetoothDeviceOtherLabel".localise()
            default:return ""
            
        }
        
    }
    
    var icon:String {
        switch self {
            case .mouse:return "magicmouse.fill"
            case .headphones:return "headphones"
            case .gamepad:return "gamecontroller.fill"
            case .speaker:return "hifispeaker.2.fill"
            case .keyboard:return "keyboard.fill"
            default:return ""
            
        }
        
    }
    
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
        
    public var battery:Bool {
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
    
    public var mac:Bool {
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
    
    public var category:SystemDeviceCategory {
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
    
    public var icon:String {
        switch self {
            case .imac: return "desktopcomputer"
            case .macMini: return "macmini"
            case .macPro: return "macpro.gen3"
            case .macStudio: return "macstudio"
            default : return "laptopcomputer"
            
        }
        
    }
    
    static func name(_ alias:Bool = true) -> String? {
        var name:String? = nil
        switch SystemDeviceTypes.type {
            case .macbook: name = "Macbook"
            case .macbookPro: name = "MacBook Pro"
            case .macbookAir: name = "MacBook Air"
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
    
    static func type(_ model:String) -> SystemDeviceTypes? {
        var formatted = model.replacingOccurrences(of: "[^A-Za-z]", with: "", options: .regularExpression)
        formatted = formatted.lowercased()
        
        return SystemDeviceTypes(rawValue: formatted)
        
    }

    static var serial:String? {
        #if os(macOS)
            var output: String? = nil
            let expert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

            if expert != 0 {
                let serialNumberAsCFString = IORegistryEntryCreateCFProperty(expert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String
                output = serialNumberAsCFString
                
                IOObjectRelease(expert)
                
            }
    
            return output
                   
        #elseif os(iOS)
           return nil

        #endif
        
    }
    
    static var model:String {
        #if os(macOS)
            var size = 0
            sysctlbyname("hw.model", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0,  count: size)
            sysctlbyname("hw.model", &machine, &size, nil, 0)
            return String(cString: machine)

        #elseif os(iOS)
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
               guard let value = element.value as? Int8, value != 0 else { return identifier }
               return identifier + String(UnicodeScalar(UInt8(value)))
                
            }
        
            return identifier

        #endif
        
    }
    
    static var os:String {
        #if os(macOS)
            let os = ProcessInfo.processInfo.operatingSystemVersionString
            let regex = try! NSRegularExpression(pattern: "Version (\\d+\\.\\d+)")
            if let match = regex.firstMatch(in: os, options: [], range: NSRange(location: 0, length: os.utf16.count)) {
                if let range = Range(match.range(at: 1), in: os) {
                   return String(os[range])
                   
                }
                
            }
        
            return "14.0"
        
        #elseif os(iOS)
            return UIDevice.current.systemVersion

        #endif
        
    }
    
    static var system:UUID? {
        if let system = UserDefaults.standard.object(forKey: SystemDefaultsKeys.deviceIdentifyer.rawValue) as? String {
            return UUID(uuidString: system)
    
        }
        
        return nil
        
    }
    
    static var identifyer:String {
        if let id = UserDefaults.main.object(forKey: SystemDefaultsKeys.versionIdenfiyer.rawValue) as? String {
            return id
            
        }
        else {
            var id = "US-\(UUID().uuidString)"
            #if os(macOS)
                id = "\(Locale.current.regionCode?.uppercased() ?? "US")-\(UUID().uuidString)"
            
            #elseif os(iOS)
                id = "\(Locale.current.region?.identifier.uppercased() ?? "US")-\(UUID().uuidString)"

            #endif
            
            UserDefaults.save(.versionIdenfiyer, value: id)

            return id
            
        }
        
    }
    
    static var type:SystemDeviceTypes {
        #if os(macOS)
            let platform = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

            if let model = IORegistryEntryCreateCFProperty(platform, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
                if let type = String(data: model, encoding: .utf8)?.cString(using: .utf8) {
                    if String(cString: type).lowercased().contains("macbookpro") { return .macbookPro }
                    else if String(cString: type).lowercased().contains("macbookair") { return .macbookAir }
                    else if String(cString: type).lowercased().contains("macbook") { return .macbook }
                    else if String(cString: type).lowercased().contains("imac") { return .imac }
                    else if String(cString: type).lowercased().contains("macmini") { return .macMini }
                    else if String(cString: type).lowercased().contains("macstudio") { return .macStudio }
                    else if String(cString: type).lowercased().contains("macpro") { return .macPro }
                    else { return .unknown }
                  
                }
              
            }

            IOObjectRelease(platform)
        
            return .unknown
        
        #elseif os(iOS)
            switch UIDevice.current.userInterfaceIdiom {
                case .phone:return .iphone
                case .pad:return .ipad
                default:return .unknown
                
            }

        #endif

    }
    
}

struct SystemDeviceProfileObject:Hashable,Equatable {
    static func == (lhs: SystemDeviceProfileObject, rhs: SystemDeviceProfileObject) -> Bool {
        lhs.serial == rhs.serial
        
    }
    
    var model:String
    var vendor:String?
    var serial:String?
    var hardware:String?
    var apperance:String?
    var findmy:Bool

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
    var notify:StatsNotificationType
    var device:SystemDeviceObject?

    init?(_ event:Events?) {
        if let id = event?.id, let state = StatsStateType(rawValue: event?.state ?? ""), let timestamp = event?.timestamp, let notify = event?.notify, let device = event?.device {
            self.id = id
            self.state = state
            self.created = timestamp
            self.battery = Int(event?.charge ?? 100)
            self.notify = StatsNotificationType(rawValue: notify) ?? .background
            self.device = .init(device)
            
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
    var profile:SystemDeviceProfileObject
    var connectivity:SystemConnectivityType = .system
    var synced:Bool = true
    var favourite:Bool = false
    var notifications:Bool = true
    var order:Int = 1
    var distance:SystemDeviceDistanceObject? = nil
    var added:Date? = nil
    var system:Bool = false
    
    init?(_ device:Devices) {
        if let id = device.id, let model = device.model {
            self.id = id
            self.name = device.name ?? model.replacingOccurrences(of: "[^A-Za-z]", with: "", options: .regularExpression)
            self.profile = .init(model: model, vendor: device.vendor ?? "", apperance: device.apperance, findmy:device.findmy)
            self.synced = true
            self.connectivity = device.primary ? .system : .bluetooth
            self.favourite = device.favourite
            self.notifications = device.notifications
            self.order = Int(device.order)
            self.distance = nil
            self.added = device.added_on ?? Date()
            self.system = id == SystemDeviceTypes.system ? true : false
            
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
        self.distance = distance
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        
    }
    
    static func match(_ device:SystemDeviceObject?, context:NSManagedObjectContext) -> SystemDeviceObject? {
        let fetch = Devices.fetchRequest() as NSFetchRequest<Devices>
        fetch.includesPendingChanges = true
                
        if let list = try? context.fetch(fetch) {
            let existing:[SystemDeviceObject] = list.compactMap({ .init($0) })
            
            if let device = device {
                if let address = device.address {
                    if let match = existing.first(where: { $0.address == address }) {
                        return match
                        
                    }
                    
                }
                
                if let serial = device.profile.serial {
                    if let match = existing.first(where: { $0.profile.model == device.profile.model && $0.profile.serial == serial }) {
                        return match
                        
                    }
                    
                }
                
                print("SystemDeviceTypes.model" ,SystemDeviceTypes.model)
                print("existing" ,existing.map({ $0.profile.model }))
                
                if let match = existing.first(where: { $0.profile.model == device.profile.model }) {
                    return match
                    
                }
                
                if let match = existing.first(where: { $0.name == device.name }) {
                    return match
                    
                }
                
            }
            else {
                if let serial = SystemDeviceTypes.serial {
                    if let match = existing.first(where: { $0.profile.model == SystemDeviceTypes.model && $0.profile.serial == serial }) {
                        return match
                        
                    }
                    
                }
                
                if let name = SystemDeviceTypes.name(true) {
                    if let match = existing.first(where: { $0.profile.model == SystemDeviceTypes.model && $0.name == name }) {
                        return match
                        
                    }
                    
                }
                
                if let match = existing.first(where: { $0.profile.model == SystemDeviceTypes.model }) {
                    return match
                    
                }
                
                if let match = existing.first(where: { $0.name == SystemDeviceTypes.name(true) }) {
                    return match
                    
                }
                
            }
            
            return nil
            
        }
        
        return device
        
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
    case deviceCreated = "bb_device_created"
    case deviceIdentifyer = "bb_device_identifyer"
    
    case enabledAnalytics = "bb_settings_analytics"
    case enabledLogin = "bb_settings_login"
    case enabledTheme = "bb_settings_theme"
    case enabledSoundEffects = "bb_settings_sfx"
    case enabledPinned = "bb_pinned_mode"
    case enabledBeta = "bb_beta_mode"

    case batteryUntilFull = "bb_charge_full"
    case batteryLastCharged = "bb_charge_last"
    case batteryDepletionRate = "bb_depletion_rate"
    case batteryWindowPosition = "bb_window_position"

    case versionInstalled = "bb_version_installed"
    case versionCurrent = "bb_version_current"
    case versionIdenfiyer = "bb_version_idenfiyer"
    
    case usageDay = "bb_usage_days"
    case usageTimestamp = "bb_usage_date"
    
    case menubarStyle = "bb_mbar_style"
    case menubarRadius = "bb_mbar_radius"
    case menubarAnimation = "bb_mbar_animations"
    case menubarProgress = "bb_mbar_progress"
    case menubarScheme = "bb_mbar_scheme"
    case menubarPrimary = "bb_mbar_primary"
    case menubarSecondary = "bb_mbar_secondary"
    
    case bluetoothUpdated = "bb_bluetoothlte_updated"
    case bluetoothEnabled = "bb_bluetoothlte_enabled"

    case onboardingStep = "bb_onboarding_step"
    case onboardingComplete = "bb_onboarding_updated"

    var name:String {
        switch self {
            case .deviceCreated:return "Device Created"
            case .deviceIdentifyer:return "Device ID"
            
            case .enabledAnalytics:return "Analytics"
            case .enabledLogin:return "Launch at Login"
            case .enabledTheme:return "Theme"
            case .enabledSoundEffects:return "SFX"
            case .enabledPinned:return "Pinned"
            case .enabledBeta:return "Beta Mode"

            case .batteryUntilFull:return "Seconds until Charged"
            case .batteryLastCharged:return "Seconds until Charged"
            case .batteryDepletionRate:return "Battery Depletion Rate"
            case .batteryWindowPosition:return "Battery Window Position"
            
            case .versionInstalled:return "Installed on"
            case .versionCurrent:return "Active Version"
            case .versionIdenfiyer:return "Version Idenfiyer"

            case .usageDay:return "bb_usage_days"
            case .usageTimestamp:return "bb_usage_timestamp"
            
            case .menubarStyle:return "MenuBar Style"
            case .menubarRadius:return "MenuBar Radius"
            case .menubarScheme:return "MenuBar Colour Scheme"
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
