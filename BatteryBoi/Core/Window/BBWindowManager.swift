//
//  WindowManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/5/23.
//

import Foundation
import SwiftUI
import Combine
import CoreGraphics

#if os(macOS)
    import Cocoa

#endif

struct WindowScreenSize {
    var top: CGFloat = CGFloat(NSScreen.main?.frame.origin.y ?? 0.0)
    var leading: CGFloat = CGFloat(NSScreen.main?.frame.origin.x ?? 0.0)
    var width: CGFloat = CGFloat(NSScreen.main?.frame.width ?? 0.0)
    var height: CGFloat = CGFloat(NSScreen.main?.frame.height ?? 0.0)

}

struct WindowSize {
    var width: CGFloat
    var height: CGFloat

}

enum WindowTypes: String, CaseIterable {
    case alert = "modalwindow"
    case preferences = "wreferenceswindow"
    case update = "changelogwindow"
    case onboarding = "onboardingwindow"

    var size: WindowSize {
        switch self {
            case .alert: return .init(width: 420, height: 220)
            case .preferences: return .init(width: 500, height: 600)
            case .onboarding: return .init(width: 520, height: 580)
            case .update: return .init(width: 520, height: 420)

        }

    }

}

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

enum WindowPosition: String {
    case center
    case topLeft
    case topMiddle
    case topRight
    case bottomLeft
    case bottomRight

    var alignment: Alignment {
        switch self {
            case .center: return .center
            case .topLeft: return .topLeading
            case .topMiddle: return .top
            case .topRight: return .topTrailing
            case .bottomLeft: return .bottomLeading
            case .bottomRight: return .bottomTrailing

        }

    }

}

#if os(macOS)
@objc(BBWindow)
public class BBWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true

    }

    override var canBecomeMain: Bool {
        return true

    }

}
#endif

public class WindowManager: ObservableObject {
    static var shared = WindowManager()

    private var updates = Set<AnyCancellable>()
    private var triggered: Int = 0
    private var screen: CGSize {
        if let display = CGMainDisplayID() as CGDirectDisplayID? {
            return .init(width: CGFloat(CGDisplayPixelsWide(display)), height: CGFloat(CGDisplayPixelsHigh(display)))

        }

    }

    @Published public var hover: Bool = false
    @Published public var state: SystemAlertState = .hidden
    @Published public var position: WindowPosition = .topMiddle
    @Published public var opacity: CGFloat = 1.0

    #if os(macOS)
        init() {
            UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
                switch key {
                    case .onboardingComplete: self.windowOpen(.alert, alert: .userInitiated, device: nil)
                    default: break

                }

            }.store(in: &updates)

            OnboardingManager.shared.$state.dropFirst().sink { state in
                if state == .complete {
                    WindowManager.shared.windowClose(.onboarding)

                }

            }.store(in: &updates)

            AppManager.shared.$alert.removeDuplicates().delay(for: .seconds(5.0), scheduler: RunLoop.main).sink { type in
                if AppManager.shared.alert?.timeout == true && self.state == .revealed {
                    self.windowSetState(.dismissed)

                }

            }.store(in: &updates)

            AppManager.shared.$alert.removeDuplicates().delay(for: .seconds(10.0), scheduler: RunLoop.main).sink { type in
                if AppManager.shared.alert?.timeout == false && self.state == .revealed {
                    self.windowSetState(.dismissed)

                }

            }.store(in: &updates)

            SettingsManager.shared.$pinned.sink { pinned in
                if pinned == .enabled {
                    withAnimation(Animation.easeOut) {
                        self.opacity = 1.0

                    }

                }

            }.store(in: &updates)

            NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { event in
                if NSRunningApplication.current == NSWorkspace.shared.frontmostApplication {
                    if self.state == .revealed || self.state == .progress {
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
                        WindowManager.shared.windowClose(.alert)

                    }

                }
                else if state == .progress {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.windowSetState(.revealed)

                    }

                }
                else if state == .revealed && AppManager.shared.alert?.timeout == false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.windowSetState(.detailed)

                    }

                }

            }.store(in: &updates)

        }

        public func windowSetState(_ state: SystemAlertState, animated: Bool = true) {
            if self.state != state {
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 1.0)) {
                    self.state = state

                }

            }

        }

        public func windowIsVisible(_ type: SystemAlertTypes) -> Bool {
            if let window = self.windowExists(.alert, alert: type) {
                if CGFloat(window.alphaValue) > 0.5 {
                    return true

                }

            }

            return false

        }

        public func windowOpen(_ type: WindowTypes = .alert, alert: SystemAlertTypes = .userInitiated, device: SystemDeviceObject?) {
            var type = type
            if OnboardingManager.shared.state != .complete {
                if type == .alert {
                    type = .onboarding

                }

            }

            DispatchQueue.main.async {
                if let window = self.windowExists(type, alert: alert) {
                    var hosting: (any View)?
                    switch type {
                        case .onboarding: hosting = OnboardingHost()
                        default: hosting = HUDParent(alert, device: device)

                    }

                    if let hosting = hosting {
                        if window.contentView != hosting as? NSView {
                            window.contentView = WindowHostingView(rootView: AnyView(hosting))

                        }

                    }

                    if window.canBecomeKey {
                        window.makeKeyAndOrderFront(nil)
                        window.alphaValue = 1.0

                        if AppManager.shared.alert == nil {
                            if let sfx = alert.sfx {
                                sfx.play()

                            }

                        }

                        AppManager.shared.selected = device
                        AppManager.shared.alert = alert

                        self.windowSetState(.progress)

                    }

                }

            }

        }

        public func windowClose(_ type: WindowTypes) {
            if let window = NSApplication.shared.windows.filter({$0.title == type.rawValue}).first {
                if type == .alert {
                    if AppManager.shared.alert != nil {
                        AppManager.shared.alert = nil
                        AppManager.shared.selected = nil

                        self.state = .hidden

                        window.alphaValue = 0.0

                    }

                }
                else {
                    window.close()

                }

            }

        }

        private func windowClosable(_ type: WindowTypes) -> NSWindow? {
            let bounds = WindowScreenSize()
            var window: NSWindow?

            window = NSWindow()
            window?.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window?.level = .normal
            window?.contentView?.translatesAutoresizingMaskIntoConstraints = false
            window?.center()
            window?.title = type.rawValue
            window?.collectionBehavior = [.ignoresCycle]
            window?.isMovableByWindowBackground = true
            window?.backgroundColor = .clear
            window?.isRestorable = false
            window?.setFrame(NSRect(x: (bounds.width / 2) - (type.size.width / 2), y: (bounds.height / 2) - (type.size.height / 2), width: type.size.width, height: type.size.height), display: false)
            window?.titlebarAppearsTransparent = true
            window?.titleVisibility = .hidden
            window?.toolbarStyle = .unifiedCompact
            window?.isReleasedWhenClosed = false
            window?.alphaValue = 0.0

            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                context.duration = 0.2

                window?.animator().alphaValue = 1.0

            }, completionHandler: nil)

            return window

        }

        private func windowDefault(_ type: SystemAlertTypes) -> NSWindow? {
            let bounds = WindowScreenSize()
            let type = WindowTypes.alert
            var window: NSWindow?

            window = BBWindow()
            window?.styleMask = [.borderless, .miniaturizable]
            window?.level = .statusBar
            window?.contentView?.translatesAutoresizingMaskIntoConstraints = false
            window?.center()
            window?.title = type.rawValue
            window?.isMovableByWindowBackground = true
            window?.backgroundColor = .clear
            window?.isRestorable = false
            window?.setFrame(NSRect(x: (bounds.width / 2) - (type.size.width / 2), y: bounds.height - (type.size.height + 50), width: type.size.width, height: type.size.height), display: false)
            window?.titlebarAppearsTransparent = true
            window?.titleVisibility = .hidden
            window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window?.toolbarStyle = .unifiedCompact
            window?.isReleasedWhenClosed = false
            window?.alphaValue = 0.0

            return window

        }

        private func windowExists(_ type: WindowTypes, alert: SystemAlertTypes) -> NSWindow? {
            if let window = NSApplication.shared.windows.filter({$0.title == type.rawValue}).first {
                return window

            }
            else {
                switch type {
                    case .alert: return self.windowDefault(alert)
                    default: return self.windowClosable(type)

                }

            }

        }
    
    #endif
        
}

public class WindowHostingView<Content>: NSHostingView<Content> where Content: View {
    override public func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)

        if SettingsManager.shared.enabledPinned == .enabled {
            withAnimation(Animation.easeOut) {
                if WindowManager.shared.state == .revealed {
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

}
