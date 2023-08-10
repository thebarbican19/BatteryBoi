//
//  BatteryBoiApp.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI
import EnalogClient

enum SystemEvents:String {
    case fatalError = "fatal.error"
    case userInstalled = "user.installed"
    case userClicked = "user.cta"
    case userLaunched = "user.launched"

}

enum SystemDefaultsKeys: String {
    case enabledAnalytics = "sd_settings_analytics"
    case enabledLogin = "sd_settings_login"
    case enabledEstimate = "sd_settings_estimate"
    case enabledMarquee = "sd_settings_marquee"
    case enabledStyle = "sd_settings_style"

    case versionInstalled = "sd_version_installed"
    case versionCurrent = "sd_version_current"
    
}

@main
struct BatteryBoiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            TipView().environmentObject(BatteryManager.shared)
            
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
        
        EnalogManager.main.throttle(perMinute: 3)
        EnalogManager.main.ingest(SystemEvents.userLaunched, description: "Launched JoeBattery")
        
        _ = AppManager.shared

        NSApp.setActivationPolicy(.accessory)
        
        if SettingsManager.shared.enabledAutoLaunch == .undetermined {
            SettingsManager.shared.enabledAutoLaunch = .enabled
            
        }
        
    }
    
    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        #if DEBUG
            WindowManager.shared.windowOpen(.about)
        #endif
        
        switch SettingsManager.shared.enabledEstimateStatus {
            case .enabled : SettingsManager.shared.enabledEstimateStatus = .disabled
            case .disabled : SettingsManager.shared.enabledEstimateStatus = .enabled
            default : break
            
        }
                
    }

}
