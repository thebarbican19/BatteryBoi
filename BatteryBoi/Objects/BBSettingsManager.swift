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

class SettingsManager:ObservableObject {
    static var shared = SettingsManager()
    
    @Published var menu:[SettingsActionObject] = []
    @Published var sfx:SettingsSoundEffects = .enabled
    @Published var theme:SettingsTheme = .dark
    @Published var pinned:SettingsPinned = .disabled
    @Published var charge:SettingsCharged = .disabled

    private var updates = Set<AnyCancellable>()

    init() {
        self.menu = self.settingsMenu
        self.theme = self.enabledTheme
        self.sfx = self.enabledSoundEffects
        self.pinned = self.enabledPinned
        self.charge = self.enabledChargeEighty

        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            switch key {
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
    
    public func settingsAction(_ action:SettingsActionObject) {
        if action.type == .appWebsite {
            if let url = URL(string: "http://batteryboi.ovatar.io/index?ref=app&modal=donate") {
                NSWorkspace.shared.open(url)

            }

        }
        else if action.type == .appRate {
//            if AppManager.shared.appDistribution() == .direct {
//                if let url = URL(string: "https://www.producthunt.com/posts/batteryboi") {
//                    NSWorkspace.shared.open(url)
//                    
//                }
//                
//            }

        }
//        else if action.type == .appQuit {
//            WindowManager.shared.state = .dismissed
//            
//            EnalogManager.main.ingest(SystemEvents.userUpdated, description: "User Quit")
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
//                NSApp.terminate(self)
//                
//            }
//
//        }
        else if action.type == .appInstallUpdate {
//            if let update = UpdateManager.shared.available {
//                if let url = URL(string: "http://batteryboi.ovatar.io/index?modal=update") {
//                    NSWorkspace.shared.open(url)
//                    
//                    EnalogManager.main.ingest(SystemEvents.userUpdated, description: "Updating to \(update.version.formatted)")
//                    
//                }
//                
//            }

        }
        else if action.type == .appUpdateCheck {
//            if let update = UpdateManager.shared.available {
//                if let url = URL(string: "http://batteryboi.ovatar.io/index?modal=update") {
//                    NSWorkspace.shared.open(url)
//
//                    EnalogManager.main.ingest(SystemEvents.userUpdated, description: "Updating to \(update.version.formatted)")
//
//                }
//                
//            }
//            else {
//                UpdateManager.shared.updateCheck()
//
//            }

        }
//        else if action.type == .appEfficencyMode {
//            DispatchQueue.main.async {
//                BatteryManager.shared.powerSaveMode()
//
//            }
//            
//        }
        else if action.type == .appBeta {
            
        }
        else if action.type == .appPinned {
            switch self.enabledPinned {
                case .enabled : self.enabledPinned = .disabled
                case .disabled : self.enabledPinned = .enabled

            }
            
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
//
//        if AppManager.shared.appDistribution() == .direct {
//            output.append(.init(.appUpdateCheck))
//            
//        }
//        
        output.append(.init(.appWebsite))
        output.append(.init(.appRate))

        return output
        
    }

}
