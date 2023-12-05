//
//  BBSettingsModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/21/23.
//

import Foundation

enum SettingsBatteryStyle:String {
    case chunky
    case basic
    
    var radius:CGFloat {
        switch self {
            case .basic : return 3
            case .chunky : return 5
            
        }
        
    }
    
    var size:CGSize {
        switch self {
            case .basic : return .init(width: 28, height: 13)
            case .chunky : return .init(width: 32, height: 15)
            
        }
        
    }
    
    var padding:CGFloat {
        switch self {
            case .basic : return 1
            case .chunky : return 2
            
        }
        
    }
    
}

enum SettingsBatteryAnimationType {
    case charging
    case low
    
}

enum SettingsSoundEffects:String {
    case enabled
    case disabled
    
    var subtitle:String {
        switch self {
            case .enabled : "SettingsEnabledLabel".localise()
            default : "SettingsDisabledLabel".localise()
            
        }
        
    }
    
    var icon:String {
        switch self {
            case .enabled : "AudioIcon"
            default : "MuteIcon"
            
        }
        
    }

}

enum SettingsPinned:String {
    case enabled
    case disabled
    
    var subtitle:String {
        switch self {
            case .enabled : "SettingsEnabledLabel".localise()
            default : "SettingsDisabledLabel".localise()
            
        }
        
    }
    
    var icon:String {
        switch self {
            case .enabled : "AudioIcon"
            default : "MuteIcon"
            
        }
        
    }

}

enum SettingsCharged:String {
    case enabled
    case disabled
    
    var subtitle:String {
        switch self {
            case .enabled : "SettingsEnabledLabel".localise()
            default : "SettingsDisabledLabel".localise()
            
        }
        
    }
    
    var icon:String {
        switch self {
            case .enabled : "AudioIcon"
            default : "MuteIcon"
            
        }
        
    }

}

enum SettingsBeta:String {
    case enabled
    case disabled
    
    var subtitle:String {
        switch self {
            case .enabled : "SettingsEnabledLabel".localise()
            default : "SettingsDisabledLabel".localise()
            
        }
        
    }
    
    var icon:String {
        switch self {
            case .enabled : "AudioIcon"
            default : "MuteIcon"
            
        }
        
    }

}

enum SettingsDisplayType:String {
    case countdown
    case empty
    case percent
    case cycle
    case hidden
    
    var type:String {
        switch self {
            case .countdown : return "SettingsDisplayEstimateLabel".localise()
            case .percent : return "SettingsDisplayPercentLabel".localise()
            case .empty : return "SettingsDisplayNoneLabel".localise()
            case .cycle : return "SettingsDisplayCycleLabel".localise()
            case .hidden : return "SettingsDisplayHiddenLabel".localise()

        }
        
    }
    
    var icon:String {
        switch self {
            case .countdown : return "TimeIcon"
            case .percent : return "PercentIcon"
            case .cycle : return "CycleIcon"
            case .empty : return "EmptyIcon"
            case .hidden : return "EmptyIcon"

        }
        
    }
    
}

struct SettingsActionObject:Hashable {
    var type:SettingsActionType
    var title:String

    init(_ type:SettingsActionType) {
        switch type {
            case .appWebsite : self.title = "SettingsWebsiteLabel".localise()
            case .appQuit : self.title = "SettingsQuitLabel".localise()
            case .appDevices : self.title = "SettingsDevicesLabel".localise()
            case .appSettings : self.title = "SettingsSettingsLabel".localise()
            case .appEfficencyMode : self.title = "SettingsEfficiencyLabel".localise()
            case .appBeta : self.title = "SettingsPrereleasesLabel".localise()
            case .appRate : self.title = "SettingsRateLabel".localise()
            case .appUpdateCheck : self.title = "SettingsCheckUpdatesLabel".localise()
            case .appInstallUpdate : self.title = "SettingsNewUpdateLabel".localise()
            case .appPinned : self.title = "SettingsPinnedLabel".localise()
            case .customiseTheme : self.title = "SettingsThemeLabel".localise()
            case .customiseDisplay : self.title = "SettingsDisplayLabel".localise()
            case .customiseNotifications : self.title = "SettingsDisplayPercentLabel".localise()
            case .customiseSoundEffects : self.title = "SettingsSoundEffectsLabel".localise()
            case .customiseCharge : self.title = "SettingsEightyLabel".localise()
            
        }
        
        self.type = type
        
    }
    
}

enum SettingsActionType {
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

    var icon:String {
        switch self {
            case .appEfficencyMode : return "EfficiencyIcon"
            case .appUpdateCheck : return "CycleIcon"
            case .appInstallUpdate : return "CycleIcon"
            case .appWebsite : return "WebsiteIcon"
            case .appBeta : return "WebsiteIcon"
            case .appQuit : return "WebsiteIcon"
            case .appDevices : return "WebsiteIcon"
            case .appSettings : return "WebsiteIcon"
            case .appPinned : return "WebsiteIcon"
            case .appRate : return "RateIcon"
            case .customiseDisplay : return "PercentIcon"
            case .customiseTheme : return "PercentIcon"
            case .customiseNotifications : return "PercentIcon"
            case .customiseSoundEffects : return "PercentIcon"
            case .customiseCharge : return "PercentIcon"

        }
        
    }
    
}

enum SettingsTheme:Int {
    case system
    case light
    case dark
    
    var string:String {
        switch self {
            case .light : return "light"
            case .dark : return "dark"
            default : return "system"
            
        }
        
    }
    
}

enum SettingsStateValue:String {
    case enabled
    case disabled
    case undetermined
    case restricted
    
    var enabled:Bool {
        switch self {
            case .disabled : return false
            default : return true
            
        }
        
    }
    
    var boolean:Bool {
        switch self {
            case .enabled : return true
            default : return false
            
        }
        
    }
    
    var title:String {
        switch self {
            case .enabled : return "Enabled"
            case .disabled : return "Disabled"
            case .undetermined : return "Not Set"
            case .restricted : return "Restricted"

        }
        
    }
    
}
