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

public class SettingsManager: ObservableObject {
    public static var shared = SettingsManager()

    @Published public var menu: [SettingsActionObject] = []
    @Published public var sfx: SettingsSoundEffects = .enabled
    @Published public var theme: SettingsTheme = .dark
    @Published public var pinned: SettingsPinned = .disabled
    @Published public var charge: SettingsCharged = .disabled

    private var updates = Set<AnyCancellable>()

    public init() {
        self.menu = self.settingsMenu
        self.theme = self.enabledTheme
        self.sfx = self.enabledSoundEffects
        self.pinned = self.enabledPinned

        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            switch key {
                case .enabledTheme: self.theme = self.enabledTheme
                case .enabledSoundEffects: self.sfx = self.enabledSoundEffects
                case .enabledPinned: self.pinned = self.enabledPinned
                default: break

            }

        }.store(in: &updates)

    }

    deinit {
        self.updates.forEach { $0.cancel() }

    }
    
    public var enabledAutoLaunch: SettingsStateValue {
        get {
            if #available(macOS 13.0, *) {
                if UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledLogin.rawValue) == nil {
                    return .undetermined

                }
                else {
                    switch SMAppService.mainApp.status == .enabled {
                        case true: return .enabled
                        case false: return .disabled

                    }

                }

            }

            return .restricted

        }

        set {
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

                    UserDefaults.save(.enabledLogin, value: SettingsStateValue.restricted)

                }

            }
            else {
                UserDefaults.save(.enabledLogin, value: SettingsStateValue.restricted)

            }

        }

    }
        
    public var enabledTheme: SettingsTheme {
        get {
            if let value = UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledTheme.rawValue) as? String {
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
            if newValue == .dark {
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
            else if newValue == .light {
                NSApp.appearance = NSAppearance(named: .aqua)
            }
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

    public var enabledBeta: SettingsBeta {
        get {
            if let key = UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledBeta.rawValue) as? String {
                return SettingsBeta(rawValue: key) ?? .disabled

            }

            return .disabled

        }

        set {
            UserDefaults.save(.enabledBeta, value: newValue.rawValue)

        }

    }

    public var enabledPinned: SettingsPinned {
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

    public var enabledSoundEffects: SettingsSoundEffects {
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
    
    public func settingsAction(_ action: SettingsActionObject) {
        if action.type == .appWebsite {
            if let url = URL(string: "http://batteryboi.ovatar.io/index?ref=app&modal=donate") {
                NSWorkspace.shared.open(url)

            }

        }
        else if action.type == .appRate {

        }
        else if action.type == .appInstallUpdate {

        }
        else if action.type == .appUpdateCheck {

        }
        else if action.type == .appPinned {
            switch self.enabledPinned {
                case .enabled: self.enabledPinned = .disabled
                case .disabled: self.enabledPinned = .enabled

            }

        }
        else if action.type == .customiseSoundEffects {
            switch self.enabledSoundEffects {
                case .enabled: self.enabledSoundEffects = .disabled
                case .disabled: self.enabledSoundEffects = .enabled

            }

        }

    }

    private var settingsMenu: [SettingsActionObject] {
        var output = Array<SettingsActionObject>()

        #if DEBUG
            output.append(.init(.appPinned))

        #endif

        output.append(.init(.customiseDisplay))
        output.append(.init(.customiseSoundEffects))

        #if DEBUG
            output.append(.init(.customiseCharge))
        #endif

        output.append(.init(.appWebsite))
        output.append(.init(.appRate))

        return output

    }

    public func settingsReset() {
        UserDefaults.save(.enabledSoundEffects, value: nil)
        UserDefaults.save(.enabledTheme, value: nil)
        UserDefaults.save(.enabledAnalytics, value: nil)

    }

}
