//
//  BatteryBoiApp.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI
import EnalogSwift
import Sparkle

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
        switch self {
            case .macbook: return "Macbook"
            case .macbookPro: return "Macbook Pro"
            case .macbookAir: return "Macbook Air"
            case .imac: return "iMac"
            case .macMini: return "Mac Mini"
            case .macPro: return "Mac Pro"
            case .macStudio: return "Mac Pro"
            case .unknown: return "Unknown"
            
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
    
}

enum SystemEvents:String {
    case fatalError = "fatal.error"
    case userInstalled = "user.installed"
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
    
    case batteryUntilFull = "sd_charge_full"
    case batteryLastCharged = "sd_charge_last"
    case batteryDepletionRate = "sd_depletion_rate"

    case versionInstalled = "sd_version_installed"
    case versionCurrent = "sd_version_current"
    case versionIdenfiyer = "sd_version_id"

    var name:String {
        switch self {
            case .enabledAnalytics:return "Analytics"
            case .enabledLogin:return "Launch at Login"
            case .enabledEstimate:return "Battery Time Estimate"
            case .enabledBluetooth:return "Bluetooth"
            case .enabledStyle:return "Icon Style"
            case .enabledDisplay:return "Icon Display Text"
            case .enabledTheme:return "Theme"
            
            case .batteryUntilFull:return "Seconds until Charged"
            case .batteryLastCharged:return "Seconds until Charged"
            case .batteryDepletionRate:return "Battery Depletion Rate"
            case .versionInstalled:return "Installed on"
            case .versionCurrent:return "Active Version"
            case .versionIdenfiyer:return "App ID"

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

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.status = NSStatusBar.system.statusItem(withLength: 45)
        self.hosting.frame.size = NSSize(width: 45, height: 22)
        
        if let button = self.status?.button {
            button.title = ""
            button.addSubview(self.hosting)
            button.action = #selector(statusBarButtonClicked(sender:))
            button.target = self
            
        }
        
        if let window = NSApplication.shared.windows.first {
            window.close()

        }
        
        if let channel = Bundle.main.infoDictionary?["SD_SLACK_CHANNEL"] as? String  {
            EnalogManager.main.user(AppManager.shared.appIdentifyer)
            EnalogManager.main.crash(SystemEvents.fatalError, channel: .init(.slack, id:channel))
            EnalogManager.main.ingest(SystemEvents.userLaunched, description: "Launched BatteryBoi")

        }
        
        _ = SettingsManager.shared.enabledTheme
        
        UpdateManager.shared.updateCheck(false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            switch BatteryManager.shared.charging.state {
                case .battery : WindowManager.shared.windowOpen(.userLaunched, device: nil)
                case .charging : WindowManager.shared.windowOpen(.chargingBegan, device: nil)
                
            }
            
        }
        
        NSApp.setActivationPolicy(.accessory)
        
        if #available(macOS 13.0, *) {
            if SettingsManager.shared.enabledAutoLaunch == .undetermined {
                SettingsManager.shared.enabledAutoLaunch = .enabled
                
            }
            
        }
        
    }
    
    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        WindowManager.shared.windowOpen(.userInitiated, device: nil)
                
    }

}
