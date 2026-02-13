//
//  BatteryBoiApp.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI
import EnalogSwift
import Sparkle
import Combine
import Foundation

public enum SystemDistribution {
    case direct
    case appstore
    
}

public struct SystemProfileObject:Codable {
    var id:String
    var display:String
    
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
            NSSound(named: self.rawValue)?.play()

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
    case unknown
    
    var name:String {
        if let name = Host.current().localizedName {
            return name
            
        }
        else {
            switch self {
                case .macbook: return "Macbook"
                case .macbookPro: return "Macbook Pro"
                case .macbookAir: return "Macbook Air"
                case .imac: return "iMac"
                case .macMini: return "Mac Mini"
                case .macPro: return "Mac Pro"
                case .macStudio: return "Mac Pro"
                case .unknown: return "AlertDeviceUnknownTitle".localise()
                
            }
            
        }
        
    }
    
    var battery:Bool {
        switch self {
            case .macbook: return true
            case .macbookPro: return true
            case .macbookAir: return true
            case .imac: return false
            case .macMini: return false
            case .macPro: return false
            case .macStudio: return false
            case .unknown: return false
            
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
    case enabledAnalytics = "sd_settings_analytics"
    case enabledLogin = "sd_settings_login"
    case enabledEstimate = "sd_settings_estimate"
    case enabledBluetooth = "sd_bluetooth_state"
    case enabledDisplay = "sd_settings_display"
    case enabledStyle = "sd_settings_style"
    case enabledTheme = "sd_settings_theme"
    case enabledSoundEffects = "sd_settings_sfx"
    case enabledChargeEighty = "sd_charge_eighty"
    case enabledProgressState = "sd_progress_state"
    case enabledPinned = "sd_pinned_mode"

    case batteryMinChargeThreshold = "sd_battery_min_threshold"
    case batteryMaxChargeThreshold = "sd_battery_max_threshold"

    case batteryUntilFull = "sd_charge_full"
    case batteryLastCharged = "sd_charge_last"
    case batteryDepletionRate = "sd_depletion_rate"
    case batteryWindowPosition = "sd_window_position"

    case versionInstalled = "sd_version_installed"
    case versionCurrent = "sd_version_current"
    case versionIdenfiyer = "sd_version_id"

    case usageDay = "sd_usage_days"
    case usageTimestamp = "sd_usage_date"

    case profileChecked = "sd_profiles_checked"
    case profilePayload = "sd_profiles_payload"

    var name:String {
        switch self {
            case .enabledAnalytics:return "Analytics"
            case .enabledLogin:return "Launch at Login"
            case .enabledEstimate:return "Battery Time Estimate"
            case .enabledBluetooth:return "Bluetooth"
            case .enabledStyle:return "Icon Style"
            case .enabledDisplay:return "Icon Display Text"
            case .enabledTheme:return "Theme"
            case .enabledSoundEffects:return "SFX"
            case .enabledChargeEighty:return "Show complete at 80%"
            case .enabledProgressState:return "Show Progress"
            case .enabledPinned:return "Pinned"

            case .batteryMinChargeThreshold:return "Minimum Battery Threshold"
            case .batteryMaxChargeThreshold:return "Maximum Charge Threshold"

            case .batteryUntilFull:return "Seconds until Charged"
            case .batteryLastCharged:return "Seconds until Charged"
            case .batteryDepletionRate:return "Battery Depletion Rate"
            case .batteryWindowPosition:return "Battery Window Positio"

            case .versionInstalled:return "Installed on"
            case .versionCurrent:return "Active Version"
            case .versionIdenfiyer:return "App ID"

            case .usageDay:return "sd_usage_days"
            case .usageTimestamp:return "sd_usage_timestamp"

            case .profileChecked:return "Profile Validated"
            case .profilePayload:return "Profile Payload"

        }

    }

}

@main
struct BatteryBoiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            EmptyView()

        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        
    }
    
}

class CustomView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Draw or add your custom elements here
        
    }
    
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate, ObservableObject {
    static var shared = AppDelegate()
    
    public var status:NSStatusItem? = nil
    public var hosting:NSHostingView = NSHostingView(rootView: MenuContainer())
    public var updates = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.status = NSStatusBar.system.statusItem(withLength: 45)
        self.hosting.frame.size = NSSize(width: 45, height: 22)
        
        if let window = NSApplication.shared.windows.first {
            window.close()

        }
        
        if let channel = Bundle.main.infoDictionary?["SD_SLACK_CHANNEL"] as? String  {
            #if !DEBUG
                EnalogManager.main.user(AppManager.shared.appIdentifyer)
                EnalogManager.main.crash(SystemEvents.fatalError, channel: .init(.slack, id:channel))
                EnalogManager.main.ingest(SystemEvents.userLaunched, description: "Launched BatteryBoi")
            
            #endif

        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            _ = SettingsManager.shared.enabledTheme
            _ = SettingsManager.shared.enabledDisplay()
            
            _ = EventManager.shared
            
            print("\n\nApp Installed: \(AppManager.shared.appInstalled)\n\n")
            print("App Usage (Days): \(AppManager.shared.appUsage?.day ?? 0)\n\n")

            UpdateManager.shared.updateCheck()
            
            WindowManager.shared.windowOpen(.userLaunched, device: nil)
            
            SettingsManager.shared.$display.sink { type in
                switch type {
                    case .hidden : self.applicationMenuBarIcon(false)
                    default : self.applicationMenuBarIcon(true)
                    
                }
                
            }.store(in: &self.updates)
            
            if #available(macOS 13.0, *) {
                if SettingsManager.shared.enabledAutoLaunch == .undetermined {
                    SettingsManager.shared.enabledAutoLaunch = .enabled
                    
                }
                
            }
            
        }
        
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(applicationHandleURLEvent(event:reply:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(applicationDidWakeNotification(_:)), name: NSWorkspace.didWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(applicationDidSleepNotification(_:)), name: NSWorkspace.screensDidSleepNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationFocusDidMove(notification:)), name: NSWindow.didMoveNotification, object:nil)
        
    }
    
    private func applicationMenuBarIcon(_ visible:Bool) {
        if visible == true {
            if let button = self.status?.button {
                button.title = ""
                button.addSubview(self.hosting)
                button.action = #selector(applicationStatusBarButtonClicked(sender:))
                button.target = self
                
                SettingsManager.shared.enabledPinned = .disabled
                
            }
            
        }
        else {
            if let button = self.status?.button {
                button.subviews.forEach { $0.removeFromSuperview() }
                
            }
            
        }
        
    }
    
    @objc func applicationStatusBarButtonClicked(sender: NSStatusBarButton) {
        if WindowManager.shared.windowIsVisible(.userInitiated) == false {
            WindowManager.shared.windowOpen(.userInitiated, device: nil)

        }
        else {
            WindowManager.shared.windowSetState(.dismissed)
            
        }
                
    }
    
    @objc func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        WindowManager.shared.windowOpen(.userInitiated, device: nil)

        return false
        
    }
    
    @objc func applicationHandleURLEvent(event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        
//        if let path = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue?.components(separatedBy: "://").last {
//            
//        }
        
    }

    @objc func applicationFocusDidMove(notification:NSNotification) {
        if let window = notification.object as? NSWindow {
            if window.title == "modalwindow" {
                NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { _ in
                    window.animator().alphaValue = 1.0;
                    window.animator().setFrame(WindowManager.shared.windowHandleFrame(), display: true, animate: true)
                    
                }
                
                _ = WindowManager.shared.windowHandleFrame(moved: window.frame)
                
            }

        }
        
    }
    
    @objc private func applicationDidWakeNotification(_ notification: Notification) {
        BatteryManager.shared.powerForceRefresh()
        
    }
    
    @objc private func applicationDidSleepNotification(_ notification: Notification) {
        
    }
    
}
