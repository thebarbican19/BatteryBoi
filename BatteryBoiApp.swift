//
//  BatteryBoiApp.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI

enum SystemDefaultsKeys: String {
    case enabledAnalytics = "sd_settings_analytics"
    case enabledLogin = "sd_settings_login"
    case enabledEstimate = "sd_settings_estimate"

    case versionCurrent = "sd_version_current"
    case versionCache = "sd_version_cache"
    
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
            
            print("Buttin Apperance: " ,button.effectiveAppearance.name)

        }
        
        if let window = NSApplication.shared.windows.first {
            window.close()

        }
        
        NSApp.setActivationPolicy(.accessory)
        
    }
    
    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        //WindowManager.shared.windowOpen(.about)
        
    }

}
