//
//  WindowManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/5/23.
//

import Foundation
import Cocoa
import SwiftUI
import Combine

struct WindowViewBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .underWindowBackground

        return view
        
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        
    }
    
}

struct WindowScreenSize {
    var top:CGFloat = CGFloat(NSScreen.main?.frame.origin.y ?? 0.0)
    var leading:CGFloat = CGFloat(NSScreen.main?.frame.origin.x ?? 0.0)
    var width:CGFloat = CGFloat(NSScreen.main?.frame.width ?? 0.0)
    var height:CGFloat = CGFloat(NSScreen.main?.frame.height ?? 0.0)
    
}

class WindowManager: ObservableObject {
    static var shared = WindowManager()
        
    private var updates = Set<AnyCancellable>()
      
    @Published public var active: Int = 0
    @Published public var hover: Int = 0
    @Published public var state: ModalAnimationTypes = .initial
    @Published public var type: ModalAnimationTypes = .initial
    
    init() {
        BatteryManager.shared.$charging.dropFirst().removeDuplicates().sink { charging in
            switch charging.state {
                case .battery : self.windowOpen(.chargingStopped, device: nil)
                case .charging : self.windowOpen(.chargingBegan, device: nil)
                
            }
            
        }.store(in: &updates)
        
        BatteryManager.shared.$percentage.dropFirst().removeDuplicates().sink { percent in
            if BatteryManager.shared.charging.state == .battery {
                switch percent {
                    case 25 : self.windowOpen(.percentTwentyFive, device: nil)
                    case 10 : self.windowOpen(.percentTen, device: nil)
                    case 5 : self.windowOpen(.percentFive, device: nil)
                    case 1 : self.windowOpen(.percentOne, device: nil)
                    default : break
                    
                }
            
            }
            else {
                if percent == 100 {
                    self.windowOpen(.chargingComplete, device: nil)
                    
                }
                
            }
                        
        }.store(in: &updates)
        
//        #if DEBUG
//            BluetoothManager.shared.$list.removeDuplicates().dropFirst().receive(on: DispatchQueue.main).sink() { items in
//                if let latest = items.sorted(by: { $0.updated > $1.updated }).first {
//                    if latest.updated.now == true && (latest.battery.general != nil || latest.battery.left != nil || latest.battery.right != nil) {
//                        
//                        switch latest.connected {
//                            case .connected : self.windowOpen(.deviceConnected, device: latest)
//                            default : self.windowOpen(.deviceRemoved, device: latest)
//                            
//                        }
//
//                    }
//                    
//                }
//
//            }.store(in: &updates)
//        
//            AppManager.shared.appTimer(60).dropFirst().receive(on: DispatchQueue.main).sink { _ in
//                let connected = BluetoothManager.shared.list.filter({ $0.connected == .connected })
//                
//                for device in connected {
//                    switch device.battery.general {
//                        case 25 : self.windowOpen(.percentTwentyFive, device: device)
//                        default : break
//
//                    }
//
//                }
//                
//            }.store(in: &updates)
//
//        #endif
    
        $state.removeDuplicates().sink { state in
            if state == .dismiss {
                WindowManager.shared.windowClose()
                
            }

        }.store(in: &updates)
        
        AppManager.shared.appTimer(1).dropFirst().receive(on: DispatchQueue.main).sink { _ in
            if self.hover > 0 && self.state == .reveal {
                self.hover += 1
                
            }
            
            if self.hover == 3 && self.state != .expand {
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 1.0)) {
                    self.hover = 0
                    self.state = .expand
                    
                }
                              
            }
            
            if (self.state == .reveal || self.state == .expand) && self.hover == 0 {
                self.active += 1

                if self.state == .reveal && self.active > 3 && self.hover == 0 {
                    withAnimation(Animation.easeIn(duration: 0.3).delay(0.1)) {
                        self.state = .dismiss
                        self.hover = 0
                        
                    }
                    
                }
                
            }
            
        }.store(in: &updates)
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { event in
            if NSRunningApplication.current == NSWorkspace.shared.frontmostApplication {
                if self.state == .reveal {
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 1.0)) {
                        self.state = .expand

                    }
                    
                }
                
            }
            else {
                withAnimation(Animation.easeIn(duration: 0.3).delay(0.1)) {
                    self.state = .dismiss
                    
                }
                
            }
            
        }
        
    }
    
    public func windowIsVisible(_ type:ModalAlertTypes) -> Bool {
        if let window = self.windowExists(type) {
            if CGFloat(window.alphaValue) > 0.5 {
                return true
                
            }
            
        }
        
        return false
        
    }
    
    public func windowOpen(_ type:ModalAlertTypes, device:BluetoothObject?) {
        if let window = self.windowExists(type) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                window.contentView = NSHostingController(rootView: ModalContainer(type, device: device)).view
                
                DispatchQueue.main.async {
                    if window.canBecomeKeyWindow {
                        window.makeKeyAndOrderFront(nil)
                        
                    }
                    
                    AppManager.shared.device = device
                    AppManager.shared.alert = type
                    
                }
                
            }

        }

    }

    public func windowClose() {
        if let window = NSApplication.shared.windows.filter({$0.title == "modalwindow"}).first {
            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                context.duration = 1.0
                
                window.animator().alphaValue = 0.0;

                
            }) {
                AppManager.shared.alert = nil
                AppManager.shared.device = nil

                window.close()
      
            }
            
        }

    }
    
    private func windowDefault(_ type:ModalAlertTypes) -> NSWindow? {
        let bounds = WindowScreenSize()
        let size:CGSize = .init(width: 480, height: 350)
        
        var window:NSWindow?
        
        window = NSWindow()
        window?.styleMask = [.borderless, .miniaturizable]
        window?.level = .statusBar
        window?.contentView?.translatesAutoresizingMaskIntoConstraints = false
        window?.center()
        window?.title = "modalwindow"
        window?.isMovableByWindowBackground = true
        window?.backgroundColor = .clear
        window?.setFrame(NSRect(x: (bounds.width / 2) - (size.width / 2), y: bounds.height - (size.height - 40), width: size.width, height: size.height), display: false)
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.toolbarStyle = .unifiedCompact
        window?.isReleasedWhenClosed = false
        window?.alphaValue = 0.0
                             
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = 0.2
            
            window?.animator().alphaValue = 1.0
            
        }, completionHandler: nil)
        
        return window
 
    }
    
    private func windowExists(_ type: ModalAlertTypes) -> NSWindow? {
        if let window = NSApplication.shared.windows.filter({$0.title == "modalwindow"}).first {
            return window
            
        }
        else {
            return self.windowDefault(type)
            
        }
                        
    }

}
