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
import CoreGraphics

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

enum WindowPosition:String {
    case center
    case topLeft
    case topMiddle
    case topRight
    case bottomLeft
    case bottomRight
    
    var alignment:Alignment {
        switch self {
            case .center:return .center
            case .topLeft:return .topLeading
            case .topMiddle:return .top
            case .topRight:return .topTrailing
            case .bottomLeft:return .bottomLeading
            case .bottomRight:return .bottomTrailing
        
        }
        
    }
    
}

class WindowManager: ObservableObject {
    static var shared = WindowManager()
    
    private var updates = Set<AnyCancellable>()
    private var triggered:Int = 0;
    private var screen:CGSize {
        if let display = CGMainDisplayID() as CGDirectDisplayID? {
            return .init(width: CGFloat(CGDisplayPixelsWide(display)) + CGFloat(40.0), height:CGFloat(CGDisplayPixelsHigh(display)))

        }
        
    }
    
    @Published public var active: Int = 0
    @Published public var hover: Bool = false
    @Published public var state: HUDState = .hidden
    @Published public var position: WindowPosition = .topMiddle
    @Published public var opacity: CGFloat = 1.0

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
                if percent == 100 && SettingsManager.shared.enabledChargeEighty == .disabled {
                    self.windowOpen(.chargingComplete, device: nil)
                    
                }
                else if percent == 80 && SettingsManager.shared.enabledChargeEighty == .enabled {
                    self.windowOpen(.chargingComplete, device: nil)
                    
                }
                
            }
            
        }.store(in: &updates)
        
        #if DEBUG
            BluetoothManager.shared.$connected.removeDuplicates().dropFirst(1).receive(on: DispatchQueue.main).sink() { items in
                if let latest = items.sorted(by: { $0.updated > $1.updated }).first {
                    if latest.updated.now == true {
                        switch latest.connected {
                            case .connected : self.windowOpen(.deviceConnected, device: latest)
                            default : self.windowOpen(.deviceRemoved, device: latest)

                        }

                    }

                }

            }.store(in: &updates)

            AppManager.shared.appTimer(60).dropFirst().receive(on: DispatchQueue.main).sink { _ in
                let connected = BluetoothManager.shared.list.filter({ $0.connected == .connected })

                for device in connected {
                    switch device.battery.general {
                        case 25 : self.windowOpen(.percentTwentyFive, device: device)
                        case 10 : self.windowOpen(.percentTen, device: device)
                        case 5 : self.windowOpen(.percentFive, device: device)
                        case 1 : self.windowOpen(.percentOne, device: device)
                        default : break
                        
                    }

                }

            }.store(in: &updates)

        #endif
        
        SettingsManager.shared.$pinned.sink { pinned in
            if pinned == .enabled {
                withAnimation(Animation.easeOut) {
                    self.opacity = 1.0

                }
                
            }
            
        }.store(in: &updates)

        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { event in
            if NSRunningApplication.current == NSWorkspace.shared.frontmostApplication {
                if self.state == .revealed {
                    self.windowSetState(.detailed)
                    
                }
                
            }
            else {
                if SettingsManager.shared.enabledPinned == .disabled {
                    if self.state.visible == true {
                        self.windowSetState(.dismissed)
                        
                    }

                }
                else {
                    self.windowSetState(.revealed)

                }
                
            }
            
        }
        
        $state.sink { state in
            if state == .dismissed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    WindowManager.shared.windowClose()
                    
                }
                
            }
            else if state == .progress {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.windowSetState(.revealed)
                    
                }

            }
            
        }.store(in: &updates)
        
        self.position = self.windowLastPosition
        
        
    }
    
    public func windowSetState(_ state:HUDState, animated:Bool = true) {
        if self.state != state {
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 1.0)) {
                self.state = state
                
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
            window.contentView = WindowHostingView(rootView: ModalContainer(type, device: device))
            
            DispatchQueue.main.async {
                if window.canBecomeKeyWindow {
                    window.makeKeyAndOrderFront(nil)
                    window.alphaValue = 1.0
                    
                    self.windowSetState(.progress)
                    
                    if AppManager.shared.alert == nil {
                        if let sfx = type.sfx {
                            sfx.play()
                            
                        }
                        
                    }
                    
                    if BluetoothManager.shared.connected.count > 0 {
                        AppManager.shared.menu = .devices

                    }
                    
                    AppManager.shared.device = device
                    AppManager.shared.alert = type
                    
                }
                
            }
                
        }
        
    }
    
    private func windowClose() {
        if let window = NSApplication.shared.windows.filter({$0.title == "modalwindow"}).first {
            if AppManager.shared.alert != nil {
                AppManager.shared.alert = nil
                AppManager.shared.device = nil
                
                self.state = .hidden
                
                window.alphaValue = 0.0
                
            }

        }
        
    }
    
    private func windowDefault(_ type:ModalAlertTypes) -> NSWindow? {
        var window:NSWindow?
        window = NSWindow()
        window?.styleMask = [.borderless, .miniaturizable]
        window?.level = .statusBar
        window?.contentView?.translatesAutoresizingMaskIntoConstraints = false
        window?.center()
        window?.title = "modalwindow"
        window?.isMovableByWindowBackground = true
        window?.backgroundColor = .clear
        window?.setFrame(self.windowHandleFrame(), display: true)
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.toolbarStyle = .unifiedCompact
        window?.isReleasedWhenClosed = false
        window?.alphaValue = 0.0
        
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
    
    public func windowHandleFrame(moved: NSRect? = nil) -> NSRect {
        let windowWidth = self.screen.width / 3
        let windowHeight = self.screen.height / 2
        let windowMargin: CGFloat = 40
        
        let positionDefault = CGSize(width: 420, height: 220)
        
        if triggered > 5 {
            if let moved = moved {
                _ = self.calculateWindowLastPosition(moved: moved, windowHeight: windowHeight, windowWidth: windowWidth, windowMargin: windowMargin)
                
                return NSMakeRect(moved.origin.x, moved.origin.y, moved.width, moved.height)
                
            }
            
        }
        else {
            self.triggered += 1
            
        }
        
        return calculateInitialPosition(mode: windowLastPosition, defaultSize: positionDefault, windowMargin: windowMargin)
        
    }
    
    private var windowLastPosition:WindowPosition {
        get {
            if let position = UserDefaults.main.object(forKey: SystemDefaultsKeys.batteryWindowPosition.rawValue) as? String {
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration:  0.5)) {
                    self.position = WindowPosition(rawValue: position) ?? .topMiddle
                    
                }

            }

            return self.position

        }
        
        set {
            UserDefaults.save(.batteryWindowPosition, value: newValue.rawValue)
           
        }
                
    }

    private func calculateWindowLastPosition(moved: NSRect, windowHeight: CGFloat, windowWidth: CGFloat, windowMargin: CGFloat) -> WindowPosition {
        var positionTop: CGFloat
        var positionMode: WindowPosition
        
        if moved.midY > windowHeight {
            positionTop = self.screen.height - windowMargin
            
        } 
        else {
            positionTop = windowMargin
            
        }
        
        if moved.midX < windowWidth {
            positionMode = (positionTop == windowMargin) ? .bottomLeft : .topLeft
            
        } 
        else if moved.midX > windowWidth && moved.midX < (windowWidth * 2) {
            positionMode = (positionTop == windowMargin) ? .center : .topMiddle
            
        } 
        else if moved.midX > (windowWidth * 2) {
            positionMode = (positionTop == windowMargin) ? .bottomRight : .topRight
            
        } 
        else {
            positionMode = .center
            
        }
        
        self.windowLastPosition = positionMode
        
        return positionMode
        
    }

    private func calculateInitialPosition(mode: WindowPosition, defaultSize: CGSize, windowMargin: CGFloat) -> NSRect {
        var positionLeft: CGFloat = windowMargin
        var positionTop: CGFloat = windowMargin
        
        switch mode {
        case .center:
            positionLeft = (self.screen.width / 2) - (defaultSize.width / 2)
            positionTop = (self.screen.height / 2) - (defaultSize.height / 2)
            
        case .topLeft, .bottomLeft:
            positionLeft = windowMargin
            positionTop = (mode == .topLeft) ? self.screen.height - (defaultSize.height + windowMargin) : windowMargin
            
        case .topMiddle:
            positionLeft = (self.screen.width / 2) - (defaultSize.width / 2)
            positionTop = self.screen.height - (defaultSize.height + windowMargin)
            
        case .topRight, .bottomRight:
            positionLeft = self.screen.width - (defaultSize.width + windowMargin)
            positionTop = (mode == .topRight) ? self.screen.height - (defaultSize.height + windowMargin) : windowMargin
        }
        
        return NSMakeRect(positionLeft, positionTop, defaultSize.width, defaultSize.height)
        
    }

}

class WindowHostingView<Content>: NSHostingView<Content> where Content: View {
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        
        if SettingsManager.shared.enabledPinned == .enabled {
            withAnimation(Animation.easeOut) {
                if event.deltaY < 0 && WindowManager.shared.opacity > 0.4 {
                    WindowManager.shared.opacity += (event.deltaY / 100)
                    
                }
                else if event.deltaY > 0 && WindowManager.shared.opacity < 1.0 {
                    WindowManager.shared.opacity += (event.deltaY / 100)
                    
                }
                
            }
            
        }
        
    }
    
}
