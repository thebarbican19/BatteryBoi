//
//  BBAppConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation
import AVFoundation
import CloudKit
import SwiftData
import CoreBluetooth

#if os(macOS)
import AppKit
import IOKit

#elseif os(iOS)
import UIKit
#endif

public enum AppAuthorizationState: Int {
	case unknown = 0
	case allowed = 1
	case denied = 2
	case restricted = 3
	case undetermined = 4

	var title: String {
		switch self {
			case .allowed: return "PermissionsAllowedLabel".localise()
			case .denied: return "PermissionsDeniedLabel".localise()
			case .undetermined: return "PermissionsUndeterminedLabel".localise()
			case .restricted: return "PermissionsRestrictedLabel".localise()
			default: return "PermissionsUnknownLabel".localise()
		}
	}
}

public enum AppAlertTypes: String {
    case chargingComplete
    case chargingBegan
    case chargingStopped
    case userInitiated
    case userLaunched
    case deviceOverheating
    case deviceConnected
    case deviceDisconnected
    case deviceNearby
    case deviceDepleting

    var sfx: AppSoundEffects? {
        switch self {
            case .chargingBegan: return .high
            case .chargingComplete: return .high
            case .chargingStopped: return .low
            case .userLaunched: return nil
            case .userInitiated: return nil
            case .deviceDepleting: return .low
            case .deviceOverheating: return .low
            case .deviceDisconnected: return .low
            case .deviceConnected: return .high
            case .deviceNearby: return .high
        }
    }

    var trigger: Bool {
        switch self {
            case .chargingBegan: return true
            case .chargingStopped: return true
            case .deviceDisconnected: return true
            case .deviceConnected: return true
            default: return false
        }
    }

    var timeout: Bool {
        switch self {
            case .userLaunched: return false
            case .userInitiated: return false
            default: return true
        }
    }

    var local: Bool {
        switch self {
            case .deviceDisconnected: return true
            case .deviceOverheating: return true
            case .deviceConnected: return true
            case .chargingBegan: return true
            case .chargingStopped: return true
            default: return false
        }
    }

    var description: String {
        switch self {
            case .chargingBegan: return "Charger is Connected"
            case .chargingComplete: return "Charging Reached Max Capacity"
            case .chargingStopped: return "Charging Reached Max Capacity"
            case .userInitiated: return "Manual Trigger"
            case .userLaunched: return "Manual Trigger"
            case .deviceOverheating: return "Internal Battery Overheating"
            case .deviceConnected: return "Bluetooth Device Connected"
            case .deviceDisconnected: return "Bluetooth Device Disconnected"
            case .deviceNearby: return "Bluetooth Device Located in Proximity"
            case .deviceDepleting: return "Battery Depleted a Percentage Point"
        }
    }
}

public enum AppAlertState: Equatable {
    case hidden
    case progress
    case revealed
    case detailed
    case dismissed

    var visible: Bool {
        switch self {
            case .detailed: return true
            case .revealed: return true
            default: return false
        }
    }

    var mask: AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.6, delay: 0.2, easing: .bounce, width: 120, height: 120, blur: 0, radius: 66),
                .init(2.9, easing: .bounce, width: 430, height: 120, blur: 0, radius: 66)], id: "initial")
        }
        else if self == .detailed {
            return .init([.init(0.0, easing: .bounce, width: 440, height: 220, radius: 42)], id: "expand_out")
        }
        else if self == .dismissed {
            return .init([
                .init(0.2, easing: .bounce, width: 430, height: 120, radius: 66),
                .init(0.2, easing: .easeout, width: 120, height: 120, radius: 66),
                .init(0.3, delay: 1.0, easing: .bounce, width: 40, height: 40, opacity: 0, radius: 66)], id: "expand_close")
        }

        return nil
    }

    var glow: AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.03, easing: .easeout, opacity: 0.0, scale: 0.2),
                .init(0.4, easing: .bounce, opacity: 0.4, scale: 1.9),
                .init(0.4, easing: .easein, opacity: 0.0, blur: 2.0)])
        }
        else if self == .dismissed {
            return .init([
                .init(0.03, easing: .easeout, opacity: 0.0, scale: 0.2),
                .init(0.4, easing: .easein, opacity: 0.6, scale: 1.4),
                .init(0.2, easing: .bounce, opacity: 0.0, scale: 0.2)])
        }

        return nil
    }

    var progress: AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.2, easing: .bounce, opacity: 0.0, blur: 0.0, scale: 0.8),
                .init(0.4, delay: 0.4, easing: .easeout, opacity: 1.0, scale: 1.0)])
        }
        else if self == .dismissed {
            return .init([.init(0.6, easing: .bounce, opacity: 0.0, blur: 12.0, scale: 0.9)])
        }

        return nil
    }

    var container: AnimationObject? {
        if self == .detailed {
            return .init([.init(0.4, easing: .easeout, padding: .init(top: 24, bottom: 16))], id: "hud_expand")
        }
        else if self == .dismissed {
            return .init([.init(0.6, delay: 0.2, easing: .easeout, opacity: 0.0, blur: 5.0)])
        }

        return nil
    }
}

public enum AppDistribution {
    case direct
    case appstore
}

public enum AppMenuView: String {
    case settings
    case stats
    case devices
}

public struct AppUsage {
    var day: Int
    var timestamp: Date
}

public enum AppSoundEffects: String {
    case high = "highnote"
    case low = "lownote"

    public func play(_ force: Bool = false) {
		#if os(macOS)
        if SettingsManager.shared.enabledSoundEffects == .enabled || force == true {
            NSSound(named: self.rawValue)?.play()
        }
		#elseif os(iOS)
			
		#endif

    }
}

public enum AppDeviceCategory: String, Codable {
    case desktop
    case laptop
    case tablet
    case smartphone
    case mouse
    case headphones
    case gamepad
    case speaker
    case keyboard
    case tracker
    case watch
    case earbuds
    case stylus
    case camera
    case remote
    case sensor
    case healthDevice
    case unknown
    case other

    var name: String {
        switch self {
            case .mouse: return "BluetoothDeviceMouseLabel".localise()
            case .headphones: return "BluetoothDeviceHeadphonesLabel".localise()
            case .gamepad: return "BluetoothDeviceGamepadLabel".localise()
            case .speaker: return "BluetoothDeviceSpeakerLabel".localise()
            case .keyboard: return "BluetoothDeviceKeyboardLabel".localise()
            case .tracker: return "Tracker"
            case .watch: return "Smartwatch"
            case .earbuds: return "Earbuds"
            case .stylus: return "Stylus"
            case .camera: return "Camera"
            case .remote: return "Remote"
            case .sensor: return "Sensor"
            case .healthDevice: return "Health Device"
            case .unknown: return "Unknown Device"
            case .other: return "BluetoothDeviceOtherLabel".localise()
            default: return ""
        }
    }

    var icon: String {
        switch self {
            case .mouse: return "magicmouse.fill"
            case .headphones: return "headphones"
            case .gamepad: return "gamecontroller.fill"
            case .speaker: return "hifispeaker.2.fill"
            case .keyboard: return "keyboard.fill"
            case .tracker: return "location.fill"
            case .watch: return "applewatch"
            case .earbuds: return "airpodspro"
            case .stylus: return "pencil.tip"
            case .camera: return "camera.fill"
            case .remote: return "remote.fill"
            case .sensor: return "sensor.fill"
            case .healthDevice: return "heart.fill"
            case .unknown: return "questionmark.circle.fill"
            case .other: return "questionmark.circle"
            default: return ""
        }
    }
}

public enum AppDeviceTypes: String, Codable {
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

    public var battery: Bool {
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

    public var mac: Bool {
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

    public var category: AppDeviceCategory {
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

    public var icon: String {
        switch self {
            case .imac: return "desktopcomputer"
            case .macMini: return "macmini"
            case .macPro: return "macpro.gen3"
            case .macStudio: return "macstudio"
            default: return "laptopcomputer"
        }
    }

    static func name(_ alias: Bool = true) -> String? {
        var name: String? = nil
        switch AppDeviceTypes.type {
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
            if let hostName = Host.current().localizedName {
                return hostName
            }
            #elseif os(iOS)
            return UIDevice.current.name
            #endif
        }

        return name
    }

    static func type(_ model: String) -> AppDeviceTypes? {
        var formatted = model.replacingOccurrences(of: "[^A-Za-z]", with: "", options: .regularExpression)
        formatted = formatted.lowercased()

        return AppDeviceTypes(rawValue: formatted)
    }

    #if os(macOS)
    static var serial: String? {
        var output: String? = nil
        let expert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        if expert != 0 {
            let serialNumberAsCFString = IORegistryEntryCreateCFProperty(expert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String
            output = serialNumberAsCFString

            IOObjectRelease(expert)
        }

        return output
    }

    static var model: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    #elseif os(iOS)
    static var serial: String? {
        return nil
    }

    static var model: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 else {
                return identifier
            }

            guard value != 0 else {
                return identifier
            }

            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    #else
    static var serial: String? { return nil }
    static var model: String { return "unknown" }
    #endif

    static var os: String {
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        let regex = try! NSRegularExpression(pattern: "Version (\\d+\\.\\d+)")
        if let match = regex.firstMatch(in: os, options: [], range: NSRange(location: 0, length: os.utf16.count)) {
            if let range = Range(match.range(at: 1), in: os) {
                return String(os[range])
            }
        }

        return "14.0"
    }

    static var system: UUID? {
        if let system = UserDefaults.standard.object(forKey: AppDefaultsKeys.deviceIdentifyer.rawValue) as? String {
            return UUID(uuidString: system)
        }

        return nil
    }

    static var identifyer: String {
        if let id = UserDefaults.main.object(forKey: AppDefaultsKeys.versionIdenfiyer.rawValue) as? String {
            return id
        }
        else {
            var id = "US-\(UUID().uuidString)"
            id = "\(Locale.current.regionCode?.uppercased() ?? "US")-\(UUID().uuidString)"

            UserDefaults.save(.versionIdenfiyer, value: id)

            return id
        }
    }

    #if os(macOS)
    static var type: AppDeviceTypes {
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
    }
    #else
    static var type: AppDeviceTypes {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone { return .iphone }
        else if UIDevice.current.userInterfaceIdiom == .pad { return .ipad }
        #endif
        return .unknown
    }
    #endif
}

public struct AppDeviceProfileObject: Hashable, Equatable {
	public static func == (lhs: AppDeviceProfileObject, rhs: AppDeviceProfileObject) -> Bool {
        lhs.serial == rhs.serial
    }

    var model: String
    var subtype: String? = nil
    var vendor: String?
    var serial: String?
    var hardware: String?
    var apperance: String?
    var findmy: Bool
    var aiCategory: AppDeviceCategory? = nil
    var aiConfidence: Double? = nil
    var aiSummary: String? = nil
}

public enum AppConnectivityType: String {
    case bluetooth
    case system
}

public struct AppPushObject: Identifiable {
    public static func == (lhs: AppPushObject, rhs: AppPushObject) -> Bool {
        lhs.id == rhs.id
    }

    public var id: UUID
    public var type: AppAlertTypes
    public var percentage: Int? = nil

    public init?(_ item: PushObject) {
        if let id = item.id, let type = AppAlertTypes(rawValue: item.type ?? "") {
            self.id = id
            self.type = type

            if let percent = item.percent, percent > 0 {
                self.percentage = percent
            }
        }
        else {
            return nil
        }
    }
}

public struct AppAlertObject: Identifiable {
    public static func == (lhs: AppAlertObject, rhs: AppAlertObject) -> Bool {
        lhs.id == rhs.id
    }

    public var id: UUID
    public var triggered: Date?
    public var event: AppEventObject
    public var type: AppAlertTypes

    public init?(_ alert: AlertsObject) {
        if let event = alert.event, let event = AppEventObject(event), let id = alert.id, let type = AppAlertTypes(rawValue: alert.type ?? "") {
            self.id = id
            self.event = event
            self.triggered = alert.triggeredOn
            self.type = type
        }
        else {
            return nil
        }
    }
}

public struct AppEventObject: Identifiable, Equatable {
    public static func == (lhs: AppEventObject, rhs: AppEventObject) -> Bool {
        lhs.id == rhs.id
    }

    public var id: UUID
    public var created: Date?
    public var state: BatteryChargingState
    public var thermal: BatteryThemalObject? = nil
    public var percentage: Int
    public var device: AppDeviceObject? = nil
    public var entity: BatteryObject

    public init?(_ item: BatteryObject) {
        if let id = item.id, let created = item.created, let state = BatteryChargingState(rawValue: item.state ?? "") {
            self.id = id
            self.created = created
            self.state = state
            self.percentage = item.percent ?? 0
            self.entity = item

            if let temp = item.temprature, Double(temp) > 0 {
                self.thermal = BatteryThemalObject(Double(temp))
            }

            if let device = item.device {
                self.device = AppDeviceObject(device)
            }
        }
        else {
            return nil
        }
    }
}

public struct AppDeviceObject: Hashable, Equatable, Identifiable {
    public static func == (lhs: AppDeviceObject, rhs: AppDeviceObject) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }

    public var id: UUID
    public var address: String?
    public var name: String
    public var profile: AppDeviceProfileObject
    public var connectivity: AppConnectivityType = .system
    public var synced: Bool = true
    public var notifications: Bool = true
    public var order: Int = 1
    public var distance: AppDeviceDistanceObject? = nil
    public var added: Date? = nil
    public var refreshed: Date? = nil
    public var system: Bool = false
    public var object: DevicesObject?

    public init?(_ device: DevicesObject) {
        if let id = device.id, let model = device.model {
            self.id = id
            self.name = device.name ?? model.replacingOccurrences(of: "[^A-Za-z]", with: "", options: .regularExpression)
            self.profile = .init(model: model, subtype: device.subtype, vendor: device.vendor ?? "", apperance: device.apperance, findmy: device.findmy ?? false)
            self.synced = true
            self.connectivity = (device.primary ?? false) ? .system : .bluetooth
            self.notifications = device.notifications ?? true
            self.order = device.order ?? 0
            self.distance = nil
            self.added = device.addedOn ?? Date()
            self.refreshed = device.refreshedOn
            self.system = id == AppDeviceTypes.system ? true : false
            self.object = device
        }
        else {
            return nil
        }
    }

    init(_ id: UUID, name: String, profile: AppDeviceProfileObject, connectivity: AppConnectivityType = .bluetooth, synced: Bool = false, distance: AppDeviceDistanceObject? = nil, object: DevicesObject? = nil) {
        self.id = id
        self.name = name
        self.address = ""
        self.profile = profile
        self.connectivity = connectivity
        self.synced = synced
        self.order = 0
        self.notifications = true
        self.distance = distance
        self.object = object
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func match(_ device: AppDeviceObject?, context: ModelContext) -> AppDeviceObject? {
        let descriptor = FetchDescriptor<DevicesObject>()

        if let list = try? context.fetch(descriptor) {
            let existing: [AppDeviceObject] = list.compactMap( { .init($0) })

            if let device = device {
                if let address = device.address, address.isEmpty == false {
                    if let match = existing.first(where: { $0.address == address }) {
                        return match
                    }
                }

                if let serial = device.profile.serial, serial.isEmpty == false {
                    if let match = existing.first(where: { $0.profile.model == device.profile.model && $0.profile.serial == serial }) {
                        return match
                    }
                }

                if device.name.isEmpty == false, device.profile.model.isEmpty == false {
                    if let match = existing.first(where: { $0.profile.model == device.profile.model && $0.name == device.name }) {
                        return match
                    }
                }

                if device.name.isEmpty == false, device.profile.model.isEmpty == false {
                    let normalizedName = device.name.normalizedDeviceName
                    let similarityThreshold = 0.85

                    if let match = existing.first(where: { existingDevice in
                        let existingNormalized = existingDevice.name.normalizedDeviceName
                        let similarity = normalizedName.jaroWinklerSimilarity(with: existingNormalized)
                        return existingDevice.profile.model == device.profile.model && similarity >= similarityThreshold
                    }) {
                        return match
                    }
                }

                if let deviceSummary = device.profile.aiSummary, let deviceCategory = device.profile.aiCategory, deviceSummary.isEmpty == false {
                    if let match = existing.first(where: { existingDevice in
                        guard let existingSummary = existingDevice.profile.aiSummary, let existingCategory = existingDevice.profile.aiCategory else { return false }
                        guard deviceCategory == existingCategory else { return false }
                        let similarity = deviceSummary.normalizedDeviceName.jaroWinklerSimilarity(with: existingSummary.normalizedDeviceName)
                        return similarity >= 0.75
                    }) {
                        return match
                    }
                }
            }
            else {
                if let serial = AppDeviceTypes.serial, serial.isEmpty == false {
                    if let match = existing.first(where: { $0.profile.model == AppDeviceTypes.model && $0.profile.serial == serial }) {
                        return match
                    }
                }

                if let name = AppDeviceTypes.name(true), name.isEmpty == false {
                    if let match = existing.first(where: { $0.profile.model == AppDeviceTypes.model && $0.name == name }) {
                        return match
                    }
                }

                if let match = existing.first(where: { $0.profile.model == AppDeviceTypes.model && ($0.profile.serial?.isEmpty != false) }) {
                    return match
                }
            }

            return nil
        }

        return device
    }
}

public enum AppDeviceDistanceType: Int {
    case unknown = 0
    case proximate = 1
    case near = 2
    case far = 3

    var string: String? {
        switch self {
            case .unknown: return nil
            case .proximate: return "BluetoothDistanceProximateLabel".localise()
            case .near: return "BluetoothDistanceNearLabel".localise()
            case .far: return "BluetoothDistanceFarLabel".localise()
        }
    }
}

public struct AppDeviceDistanceObject: Equatable {
    var value: Double
    var state: AppDeviceDistanceType

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

enum AppEvents: String {
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

public enum AppDefaultsKeys: String {
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

    var name: String {
        switch self {
            case .deviceCreated: return "Device Created"
            case .deviceIdentifyer: return "Device ID"

            case .enabledAnalytics: return "Analytics"
            case .enabledLogin: return "Launch at Login"
            case .enabledTheme: return "Theme"
            case .enabledSoundEffects: return "SFX"
            case .enabledPinned: return "Pinned"
            case .enabledBeta: return "Beta Mode"

            case .batteryUntilFull: return "Seconds until Charged"
            case .batteryLastCharged: return "Seconds until Charged"
            case .batteryDepletionRate: return "Battery Depletion Rate"
            case .batteryWindowPosition: return "Battery Window Position"

            case .versionInstalled: return "Installed on"
            case .versionCurrent: return "Active Version"
            case .versionIdenfiyer: return "Version Idenfiyer"

            case .usageDay: return "bb_usage_days"
            case .usageTimestamp: return "bb_usage_timestamp"

            case .menubarStyle: return "MenuBar Style"
            case .menubarRadius: return "MenuBar Radius"
            case .menubarScheme: return "MenuBar Colour Scheme"
            case .menubarPrimary: return "MenuBar Primary Display"
            case .menubarSecondary: return "MenuBar Secondary Display"
            case .menubarAnimation: return "MenuBar Pulsing Animation"
            case .menubarProgress: return "MenuBar Show Progress"

            case .onboardingStep: return "Onboarding Step"
            case .onboardingComplete: return "Onboarding Complete"

            case .bluetoothEnabled: return "Bluetooth State"
            case .bluetoothUpdated: return "Bluetooth Updated"

		}

    }
	
}
