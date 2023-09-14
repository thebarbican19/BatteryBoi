//
//  SettingsManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/5/23.
//

import Foundation
import Combine
import AppKit
import SwiftUI
import ServiceManagement
import EnalogSwift

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
            case .hidden : return "Hidden"

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
            case .appRate : return "WebsiteIcon"
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

class SettingsManager:ObservableObject {
    static var shared = SettingsManager()
    
    @Published var menu:[SettingsActionObject] = []
    @Published var display:SettingsDisplayType = .countdown
    @Published var sfx:SettingsSoundEffects = .enabled
    @Published var theme:SettingsTheme = .dark
    @Published var pinned:SettingsPinned = .disabled
    @Published var charge:SettingsCharged = .disabled

    private var updates = Set<AnyCancellable>()

    init() {
        self.menu = self.settingsMenu
        self.display = self.enabledDisplay(false)
        self.theme = self.enabledTheme
        self.sfx = self.enabledSoundEffects
        self.pinned = self.enabledPinned
        self.charge = self.enabledChargeEighty

        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            switch key {
                case .enabledDisplay : self.display = self.enabledDisplay(false)
                case .enabledTheme : self.theme = self.enabledTheme
                case .enabledSoundEffects : self.sfx = self.enabledSoundEffects
                case .enabledPinned : self.pinned = self.enabledPinned
                case .enabledChargeEighty : self.charge = self.enabledChargeEighty
                default : break
                
            }
           
        }.store(in: &updates)
        
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
    public var enabledAutoLaunch:SettingsStateValue {
        get {
            if #available(macOS 13.0, *) {
                if UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledLogin.rawValue) == nil {
                    return .undetermined
                    
                }
                else {
                    switch SMAppService.mainApp.status == .enabled {
                        case true : return .enabled
                        case false : return .disabled
                        
                    }
                    
                }
                
            }
            
            return .restricted
            
        }
        
        set {
            if self.enabledAutoLaunch != .undetermined {
                if #available(macOS 13.0, *) {
                    do {
                        if newValue == .disabled {
                            if SMAppService.mainApp.status == .enabled {
                               try SMAppService.mainApp.unregister()
                                
                           }
                    
                        }
                        else {
                            if SMAppService.mainApp.status != .enabled {
                                try SMAppService.mainApp.register()
                                
                            }
                            
                        }
                        
                        UserDefaults.save(.enabledLogin, value: newValue.enabled)
                        
                    }
                    catch {
                        EnalogManager.main.ingest(SystemEvents.fatalError, description: error.localizedDescription)
                        
                    }
                    
                }
                
            }
           
        }
        
    }
    
    public func enabledDisplay(_ toggle:Bool = false) -> SettingsDisplayType {
        var output:SettingsDisplayType = .percent

        if let type = UserDefaults.main.string(forKey: SystemDefaultsKeys.enabledDisplay.rawValue) {
            output = SettingsDisplayType(rawValue: type) ?? .percent

        }
        
        if toggle {
            switch output {
                case .countdown : output = .percent
                case .percent : output = .empty
                case .empty : output = .cycle
                case .cycle : output = .hidden
                default : output = .countdown
                
            }
                        
            UserDefaults.save(.enabledDisplay, value: output.rawValue)
            
        }
        
        switch output {
            case .hidden : NSApp.setActivationPolicy(.regular)
            default : NSApp.setActivationPolicy(.accessory)
            
        }
       
        return output
        
    }
    
    public var enabledStyle:BatteryStyle {
        get {
            if let style = UserDefaults.main.string(forKey: SystemDefaultsKeys.enabledStyle.rawValue) {
                return BatteryStyle(rawValue: style) ?? .chunky
                
            }

            return .chunky
            
        }
        
        set {
            if self.enabledStyle != newValue {
                UserDefaults.save(.enabledStyle, value: newValue)
                
            }
            
        }
        
    }
    
    public var enabledTheme:SettingsTheme {
        get {
            if let value = UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledTheme.rawValue) as? Int {
                if let theme = SettingsTheme(rawValue: value) {
                    if theme == .light {
                        NSApp.appearance = NSAppearance(named: .aqua)
                        return .light
                        
                    }
                    else if theme == .dark {
                        NSApp.appearance = NSAppearance(named: .darkAqua)
                        return .dark
                        
                    }
                    
                }
                
            }
            else {
                if (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light" {
                    return .light
                    
                }
                else {
                    return .dark
                    
                }
                
            }
            
            return .dark
            
        }
        
        set {
            if newValue == .dark { NSApp.appearance = NSAppearance(named: .darkAqua) }
            else if newValue == .light { NSApp.appearance = NSAppearance(named: .aqua) }
            else {
                if (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light") == "Light" {
                    NSApp.appearance = NSAppearance(named: .aqua)
                    
                }
                else {
                    NSApp.appearance = NSAppearance(named: .darkAqua)
                    
                }
                
            }
            
            UserDefaults.save(.enabledTheme, value: newValue.rawValue)
            
        }
        
    }
    
    public var enabledChargeEighty:SettingsCharged {
        get {
            if let key = UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledChargeEighty.rawValue) as? String {
                return SettingsCharged(rawValue: key) ?? .disabled
                
            }
            
            return .disabled
            
        }
        
        set {
            UserDefaults.save(.enabledChargeEighty, value: newValue.rawValue)
            
        }
        
    }
    
    public var enabledProgressBar:Bool {
        get {
            if UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledProgressState.rawValue) == nil {
                return false
                
            }
            else {
                return UserDefaults.main.bool(forKey: SystemDefaultsKeys.enabledProgressState.rawValue)
                
            }
        
        }
        
        set {
            UserDefaults.save(.enabledProgressState, value: newValue)
            
        }
        
    }
    
    public var enabledPinned:SettingsPinned {
        get {
            if let key = UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledPinned.rawValue) as? String {
                return SettingsPinned(rawValue: key) ?? .disabled
                
            }
            
            return .disabled
            
        }
        
        set {
            UserDefaults.save(.enabledPinned, value: newValue.rawValue)
            
        }
        
    }
    
    public var enabledSoundEffects:SettingsSoundEffects {
        get {
            if let key = UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledSoundEffects.rawValue) as? String {
                return SettingsSoundEffects(rawValue: key) ?? .enabled
                
            }
            
            return .enabled
        
        }
        
        set {
            if self.enabledSoundEffects == .disabled && newValue == .enabled {
                SystemSoundEffects.high.play(true)
                
            }
            
            UserDefaults.save(.enabledSoundEffects, value: newValue.rawValue)
            
        }
        
    }

    public var enabledBluetoothStatus:SettingsStateValue {
        get {
            if UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledBluetooth.rawValue) == nil {
                return .undetermined
                
            }
            else {
                //let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice]

                switch UserDefaults.main.bool(forKey: SystemDefaultsKeys.enabledBluetooth.rawValue) {
                    case true : return .enabled
                    case false : return .disabled
                    
                }
                
            }
            
        }
        
        set {
            if self.enabledBluetoothStatus != newValue {
                UserDefaults.save(.enabledBluetooth, value: newValue.enabled)
                
            }
            
        }
        
    }
    
    public func settingsAction(_ action:SettingsActionObject) {
        if action.type == .appWebsite {
            if let url = URL(string: "http://batteryboi.ovatar.io/index?ref=app&modal=donate") {
                NSWorkspace.shared.open(url)

            }

        }
        else if action.type == .appRate {
            if AppManager.shared.appDistribution() == .direct {
                if let url = URL(string: "https://www.producthunt.com/posts/batteryboi") {
                    NSWorkspace.shared.open(url)
                    
                }
                
            }

        }
        else if action.type == .appQuit {
            WindowManager.shared.state = .dismissed
            
            EnalogManager.main.ingest(SystemEvents.userUpdated, description: "User Quit")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                NSApp.terminate(self)
                
            }

        }
        else if action.type == .appInstallUpdate {
            if let update = UpdateManager.shared.available {
                if let url = URL(string: "http://batteryboi.ovatar.io/index?modal=update") {
                    NSWorkspace.shared.open(url)
                    
                    EnalogManager.main.ingest(SystemEvents.userUpdated, description: "Updating to \(update.version.formatted)")
                    
                }
                
            }

        }
        else if action.type == .appUpdateCheck {
            if let update = UpdateManager.shared.available {
                if let url = URL(string: "http://batteryboi.ovatar.io/index?modal=update") {
                    NSWorkspace.shared.open(url)

                    EnalogManager.main.ingest(SystemEvents.userUpdated, description: "Updating to \(update.version.formatted)")

                }
                
            }
            else {
                UpdateManager.shared.updateCheck()

            }

        }
        else if action.type == .appEfficencyMode {
            DispatchQueue.main.async {
                BatteryManager.shared.powerSaveMode()

            }
            
        }
        else if action.type == .appBeta {
            
        }
        else if action.type == .appPinned {
            switch self.enabledPinned {
                case .enabled : self.enabledPinned = .disabled
                case .disabled : self.enabledPinned = .enabled

            }
            
        }
        else if action.type == .customiseDisplay {
            _ = self.enabledDisplay(true)
            
        }
        else if action.type == .customiseSoundEffects {
            switch self.enabledSoundEffects {
                case .enabled : self.enabledSoundEffects = .disabled
                case .disabled : self.enabledSoundEffects = .enabled

            }
            
        }
        else if action.type == .customiseCharge {
            switch self.enabledChargeEighty {
                case .enabled : self.enabledChargeEighty = .disabled
                case .disabled : self.enabledChargeEighty = .enabled

            }
            
        }
        
    }
    
    private var settingsMenu:[SettingsActionObject] {
        var output = Array<SettingsActionObject>()
        
//        if #available(macOS 12.0, *) {
//            output.append(.init(.appEfficencyMode))
//            
//        }
        #if DEBUG
            output.append(.init(.appPinned))

        #endif

        output.append(.init(.customiseDisplay))
        output.append(.init(.customiseSoundEffects))
        
        #if DEBUG
            output.append(.init(.customiseCharge))
        #endif

        if AppManager.shared.appDistribution() == .direct {
            output.append(.init(.appUpdateCheck))
            
        }
        
        output.append(.init(.appWebsite))
        output.append(.init(.appRate))

        return output
        
    }

}
