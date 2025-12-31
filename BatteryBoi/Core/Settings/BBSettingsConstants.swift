//
//  BBSettingsConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation

public enum SettingsBatteryAnimationType {
    case charging
    case low
}

public enum SettingsSoundEffects: String {
    case enabled
    case disabled

    var subtitle: String {
        switch self {
            case .enabled: return "PermissionsEnabledLabel".localise()
            default: return "PermissionsDisabledLabel".localise()
        }
    }

    var icon: String {
        switch self {
            case .enabled: return "AudioIcon"
            default: return "MuteIcon"
        }
    }
}

public enum SettingsPinned: String {
    case enabled
    case disabled

    var subtitle: String {
        switch self {
            case .enabled: return "PermissionsEnabledLabel".localise()
            default: return "PermissionsDisabledLabel".localise()
        }
    }

    var icon: String {
        switch self {
            case .enabled: return "AudioIcon"
            default: return "MuteIcon"
        }
    }
}

public enum SettingsCharged: String {
    case enabled
    case disabled

    var subtitle: String {
        switch self {
            case .enabled: return "PermissionsEnabledLabel".localise()
            default: return "PermissionsDisabledLabel".localise()
        }
    }

    var icon: String {
        switch self {
            case .enabled: return "AudioIcon"
            default: return "MuteIcon"
        }
    }
}

public enum SettingsBeta: String, CaseIterable {
    case enabled
    case disabled

    var subtitle: String {
        switch self {
            case .enabled: return "PermissionsEnabledLabel".localise()
            default: return "PermissionsDisabledLabel".localise()
        }
    }
}

public struct SettingsActionObject: Hashable {
    var type: SettingsActionType
    var title: String

    init(_ type: SettingsActionType) {
        switch type {
            case .appWebsite: self.title = "SettingsWebsiteLabel".localise()
            case .appQuit: self.title = "SettingsQuitLabel".localise()
            case .appDevices: self.title = "SettingsDevicesLabel".localise()
            case .appSettings: self.title = "SettingsSettingsLabel".localise()
            case .appEfficencyMode: self.title = "SettingsEfficiencyLabel".localise()
            case .appBeta: self.title = "SettingsPrereleasesLabel".localise()
            case .appRate: self.title = "SettingsRateLabel".localise()
            case .appUpdateCheck: self.title = "SettingsCheckUpdatesLabel".localise()
            case .appInstallUpdate: self.title = "SettingsNewUpdateLabel".localise()
            case .appPinned: self.title = "SettingsPinnedLabel".localise()
            case .customiseTheme: self.title = "SettingsThemeLabel".localise()
            case .customiseDisplay: self.title = "SettingsDisplayLabel".localise()
            case .customiseNotifications: self.title = "SettingsDisplayPercentLabel".localise()
            case .customiseSoundEffects: self.title = "SettingsSoundEffectsLabel".localise()
            case .customiseCharge: self.title = "SettingsEightyLabel".localise()
        }

        self.type = type
    }
}

public enum SettingsActionType {
    case appWebsite
    case appQuit
    case appDevices
    case appSettings
    case appPinned
    case appUpdateCheck
    case appRate
    case appEfficencyMode
    case appInstallUpdate
    case appBeta
    case customiseSoundEffects
    case customiseDisplay
    case customiseTheme
    case customiseNotifications
    case customiseCharge

    var icon: String {
        switch self {
            case .appEfficencyMode: return "EfficiencyIcon"
            case .appUpdateCheck: return "CycleIcon"
            case .appInstallUpdate: return "CycleIcon"
            case .appWebsite: return "WebsiteIcon"
            case .appBeta: return "WebsiteIcon"
            case .appQuit: return "WebsiteIcon"
            case .appDevices: return "WebsiteIcon"
            case .appSettings: return "WebsiteIcon"
            case .appPinned: return "WebsiteIcon"
            case .appRate: return "RateIcon"
            case .customiseDisplay: return "PercentIcon"
            case .customiseTheme: return "PercentIcon"
            case .customiseNotifications: return "PercentIcon"
            case .customiseSoundEffects: return "PercentIcon"
            case .customiseCharge: return "PercentIcon"
        }
    }
}

public enum SettingsTheme: String, CaseIterable {
    case system
    case light
    case dark

    var name: String {
        switch self {
            case .light: return "SettingsCustomizationThemeLightLabel".localise()
            case .dark: return "SettingsCustomizationThemeDarkLabel".localise()
            default: return "SettingsCustomizationThemeSystemLabel".localise()
        }
    }
}

public enum SettingsStateValue: String {
    case enabled
    case disabled
    case undetermined
    case restricted

    var enabled: Bool {
        switch self {
            case .disabled: return false
            default: return true
        }
    }

    var boolean: Bool {
        switch self {
            case .enabled: return true
            default: return false
        }
    }

    var title: String {
        switch self {
            case .enabled: return true.string(.enabled)
            case .disabled: return false.string(.enabled)
            case .undetermined: return "Not Set"
            case .restricted: return "Restricted"
        }
    }
}
