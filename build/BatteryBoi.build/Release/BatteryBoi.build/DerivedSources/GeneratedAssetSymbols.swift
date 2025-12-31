import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "BatteryBackground" asset catalog color resource.
    static let batteryBackground = DeveloperToolsSupport.ColorResource(name: "BatteryBackground", bundle: resourceBundle)

    /// The "BatteryButton" asset catalog color resource.
    static let batteryButton = DeveloperToolsSupport.ColorResource(name: "BatteryButton", bundle: resourceBundle)

    /// The "BatteryCharging" asset catalog color resource.
    static let batteryCharging = DeveloperToolsSupport.ColorResource(name: "BatteryCharging", bundle: resourceBundle)

    /// The "BatteryDefault" asset catalog color resource.
    static let batteryDefault = DeveloperToolsSupport.ColorResource(name: "BatteryDefault", bundle: resourceBundle)

    /// The "BatteryEfficient" asset catalog color resource.
    static let batteryEfficient = DeveloperToolsSupport.ColorResource(name: "BatteryEfficient", bundle: resourceBundle)

    /// The "BatteryLow" asset catalog color resource.
    static let batteryLow = DeveloperToolsSupport.ColorResource(name: "BatteryLow", bundle: resourceBundle)

    /// The "BatterySubtitle" asset catalog color resource.
    static let batterySubtitle = DeveloperToolsSupport.ColorResource(name: "BatterySubtitle", bundle: resourceBundle)

    /// The "BatteryTitle" asset catalog color resource.
    static let batteryTitle = DeveloperToolsSupport.ColorResource(name: "BatteryTitle", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "AudioIcon" asset catalog image resource.
    static let audioIcon = DeveloperToolsSupport.ImageResource(name: "AudioIcon", bundle: resourceBundle)

    /// The "ChargingIcon" asset catalog image resource.
    static let chargingIcon = DeveloperToolsSupport.ImageResource(name: "ChargingIcon", bundle: resourceBundle)

    /// The "CycleIcon" asset catalog image resource.
    static let cycleIcon = DeveloperToolsSupport.ImageResource(name: "CycleIcon", bundle: resourceBundle)

    /// The "EfficiencyIcon" asset catalog image resource.
    static let efficiencyIcon = DeveloperToolsSupport.ImageResource(name: "EfficiencyIcon", bundle: resourceBundle)

    /// The "EmptyIcon" asset catalog image resource.
    static let emptyIcon = DeveloperToolsSupport.ImageResource(name: "EmptyIcon", bundle: resourceBundle)

    /// The "EventIcon" asset catalog image resource.
    static let eventIcon = DeveloperToolsSupport.ImageResource(name: "EventIcon", bundle: resourceBundle)

    /// The "MuteIcon" asset catalog image resource.
    static let muteIcon = DeveloperToolsSupport.ImageResource(name: "MuteIcon", bundle: resourceBundle)

    /// The "OverheatIcon" asset catalog image resource.
    static let overheatIcon = DeveloperToolsSupport.ImageResource(name: "OverheatIcon", bundle: resourceBundle)

    /// The "PercentIcon" asset catalog image resource.
    static let percentIcon = DeveloperToolsSupport.ImageResource(name: "PercentIcon", bundle: resourceBundle)

    /// The "PlugIcon" asset catalog image resource.
    static let plugIcon = DeveloperToolsSupport.ImageResource(name: "PlugIcon", bundle: resourceBundle)

    /// The "RateIcon" asset catalog image resource.
    static let rateIcon = DeveloperToolsSupport.ImageResource(name: "RateIcon", bundle: resourceBundle)

    /// The "TimeIcon" asset catalog image resource.
    static let timeIcon = DeveloperToolsSupport.ImageResource(name: "TimeIcon", bundle: resourceBundle)

    /// The "WebsiteIcon" asset catalog image resource.
    static let websiteIcon = DeveloperToolsSupport.ImageResource(name: "WebsiteIcon", bundle: resourceBundle)

}

