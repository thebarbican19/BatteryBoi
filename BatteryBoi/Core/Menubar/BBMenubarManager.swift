//
//  BBMenuManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/6/23.
//

import Foundation
import Combine
import Cocoa
import SwiftUI
import DynamicColor

enum MenubarDisplayType: String, CaseIterable {
    case countdown
    case empty
    case temprature
    case percent
    case voltage
    case cycle
    case hidden

    var type: String {
        switch self {
            case .countdown: return "SettingsDisplayEstimateLabel".localise()
            case .percent: return "SettingsDisplayPercentLabel".localise()
            case .temprature: return "SettingsDisplayTempratureLabel".localise()
            case .empty: return "SettingsDisplayNoneLabel".localise()
            case .cycle: return "SettingsDisplayCycleLabel".localise()
            case .voltage: return "SettingsDisplayVoltageLabel".localise()
            case .hidden: return "SettingsDisplayHiddenLabel".localise()

        }

    }

    var icon: String {
        switch self {
            case .countdown: return "TimeIcon"
            case .percent: return "PercentIcon"
            case .temprature: return "OverheatIcon"
            case .cycle: return "CycleIcon"
            case .voltage: return "CycleIcon"
            case .empty: return "EmptyIcon"
            case .hidden: return "EmptyIcon"

        }

    }

}

enum MenubarProgressType: String, CaseIterable {
    case progress
    case full
    case empty

    var description: String {
        switch self {
            case .progress: return "SettingsProgressDynamicLabel".localise()
            case .full: return "SettingsProgressFullLabel".localise()
            case .empty: return "SettingsProgressEmptyLabel".localise()

        }

    }

}

enum MenubarAppendType {
    case add
    case remove

    var device: String {
        switch self {
            case .add: return "ADDED"
            case .remove: return "REMOVED"

        }

    }

}

public class MenubarManager: ObservableObject {
    public static var shared = MenubarManager()

    @Published public var primary: String? = nil
    @Published public var seconary: String? = nil
    @Published var progress: MenubarProgressType = .progress
    @Published public var animation: Bool = true
    @Published public var radius: CGFloat = 6
    @Published var style: MenubarStyle = .transparent
    @Published var scheme: MenubarScheme = .monochrome

    private var updates = Set<AnyCancellable>()

    public init() {
        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            #if os(macOS)
                if key.rawValue.contains("mbar") == true {
                    self.menubarUpdateValues()

                }

            #endif

        }.store(in: &updates)

        BatteryManager.shared.$percentage.removeDuplicates().receive(on: DispatchQueue.main).sink() { newValue in
            self.menubarUpdateValues()

        }.store(in: &updates)

        BatteryManager.shared.$charging.removeDuplicates().receive(on: DispatchQueue.main).sink() { newValue in
            self.menubarUpdateValues()

        }.store(in: &updates)

        BatteryManager.shared.$thermal.receive(on: DispatchQueue.main).sink() { newValue in
            self.menubarUpdateValues()

        }.store(in: &updates)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.menubarUpdateValues()

        }

    }

    deinit {
        self.updates.forEach { $0.cancel() }

    }
    
    private func menubarUpdateValues() {
        let thermal = BatteryManager.shared.thermal
        let health = BatteryManager.shared.health
        let percentage = BatteryManager.shared.percentage
        let primary = self.menubarPrimaryDisplay
        let seconary = self.menubarSecondaryDisplay

        switch primary {
            case .percent: self.primary = "\(Int(percentage))"
            case .voltage: self.primary = "v"
            case .temprature: self.primary = "\(thermal.formatted)"
            case .cycle: self.seconary = "\(health?.cycles ?? 0)"
            case .countdown: self.primary = "TBA"
            case .hidden: self.primary = nil
            default: self.primary = ""

        }

        switch seconary {
            case .percent: self.seconary = "\(Int(percentage))"
            case .voltage: self.seconary = "v"
            case .temprature: self.seconary = "\(thermal.formatted)"
            case .cycle: self.seconary = "\(health?.cycles ?? 0)"
            case .countdown: self.seconary = "TBA"
            case .hidden: self.seconary = nil
            default: self.seconary = ""

        }

        self.progress = self.menubarProgressBar
        self.animation = self.menubarPulsingAnimation
        self.style = self.menubarStyle
        self.radius = CGFloat(self.menubarRadius)
        self.scheme = self.menubarSchemeType

    }

    private func menubarDevices() -> [SystemDeviceObject] {
        return []

    }
    
    var menubarStyle: MenubarStyle {
        get {
            if let value = UserDefaults.main.object(forKey: SystemDefaultsKeys.menubarStyle.rawValue) as? String {
                return MenubarStyle(rawValue: value) ?? .transparent

            }

            return .transparent

        }

        set {
            UserDefaults.save(.menubarRadius, value: nil)
            UserDefaults.save(.menubarStyle, value: newValue.rawValue)

        }

    }

    public var menubarRadius: Float {
        get {
            if UserDefaults.main.object(forKey: SystemDefaultsKeys.menubarRadius.rawValue) == nil {
                return 5.0

            }
            else {
                return UserDefaults.main.float(forKey: SystemDefaultsKeys.menubarRadius.rawValue)

            }

        }

        set {
            switch newValue {
                case let x where x < 2: UserDefaults.save(.menubarRadius, value: 2)
                case let x where x > 8: UserDefaults.save(.menubarRadius, value: 8)
                default: UserDefaults.save(.menubarRadius, value: newValue)

            }

        }

    }

    public var menubarPulsingAnimation: Bool {
        get {
            if UserDefaults.main.object(forKey: SystemDefaultsKeys.menubarAnimation.rawValue) == nil {
                return true

            }
            else {
                return UserDefaults.main.bool(forKey: SystemDefaultsKeys.menubarAnimation.rawValue)

            }

        }

        set {
            UserDefaults.save(.menubarAnimation, value: newValue)

        }

    }

    var menubarProgressBar: MenubarProgressType {
        get {
            if let type = UserDefaults.main.string(forKey: SystemDefaultsKeys.menubarProgress.rawValue) {
                return MenubarProgressType(rawValue: type) ?? .progress

            }

            return .progress

        }

        set {
            UserDefaults.save(.menubarProgress, value: newValue.rawValue)

        }

    }

    var menubarSchemeType: MenubarScheme {
        get {
            if let type = UserDefaults.main.string(forKey: SystemDefaultsKeys.menubarScheme.rawValue) {
                return MenubarScheme(rawValue: type) ?? .monochrome

            }

            return .monochrome

        }

        set {
            UserDefaults.save(.menubarScheme, value: newValue.rawValue)

        }

    }

    var menubarPrimaryDisplay: MenubarDisplayType {
        set {
            UserDefaults.save(.menubarPrimary, value: newValue.rawValue)

        }

        get {
            var output: MenubarDisplayType = .percent

            if let type = UserDefaults.main.string(forKey: SystemDefaultsKeys.menubarPrimary.rawValue) {
                output = MenubarDisplayType(rawValue: type) ?? .percent

            }

            if BatteryManager.shared.charging == .charging {
                if output != .hidden && output != .empty {
                    output = .percent

                }

            }

            if SystemDeviceTypes.type.battery == false {
                output = .voltage

            }

            #if MAINTARGET
                switch output {
                    case .hidden: NSApp.setActivationPolicy(.regular)
                    default: NSApp.setActivationPolicy(.accessory)

                }

            #endif

            return output

        }

    }

    var menubarSecondaryDisplay: MenubarDisplayType {
        set {
            UserDefaults.save(.menubarSecondary, value: newValue.rawValue)

        }

        get {
            var output: MenubarDisplayType = .countdown

            if let type = UserDefaults.main.string(forKey: SystemDefaultsKeys.menubarPrimary.rawValue) {
                output = MenubarDisplayType(rawValue: type) ?? .countdown

            }

            if SystemDeviceTypes.type.battery == false {
                output = .hidden

            }

            if self.menubarPrimaryDisplay == .empty {
                output = .percent

            }
            else if self.menubarPrimaryDisplay == output {
                output = .hidden

            }

            return output

        }

    }

    func menubarAppendDevices(_ device: SystemDeviceObject, state: MenubarAppendType) -> String {
        if let _ = AppManager.shared.appStorageContext() {

        }

        return "\n\u{001B}[1m\u{001B}[32m\("ADDED DEVICE")\u{001B}[0m\n"

    }

    public func menubarReset() {
        UserDefaults.save(.menubarPrimary, value: nil)
        UserDefaults.save(.menubarSecondary, value: nil)
        UserDefaults.save(.menubarRadius, value: nil)
        UserDefaults.save(.menubarProgress, value: nil)
        UserDefaults.save(.menubarAnimation, value: nil)
        UserDefaults.save(.menubarScheme, value: nil)
        UserDefaults.save(.menubarStyle, value: nil)

    }
    
}

