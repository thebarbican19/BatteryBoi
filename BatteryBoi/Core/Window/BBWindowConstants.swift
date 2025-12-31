//
//  BBWindowConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation
import SwiftUI
import CoreGraphics
#if os(macOS)
import Cocoa

struct WindowScreenSize {
    var top: CGFloat = CGFloat(NSScreen.main?.frame.origin.y ?? 0.0)
    var leading: CGFloat = CGFloat(NSScreen.main?.frame.origin.x ?? 0.0)
    var width: CGFloat = CGFloat(NSScreen.main?.frame.width ?? 0.0)
    var height: CGFloat = CGFloat(NSScreen.main?.frame.height ?? 0.0)
}
#else
struct WindowScreenSize {
    var top: CGFloat = 0.0
    var leading: CGFloat = 0.0
    var width: CGFloat = 0.0
    var height: CGFloat = 0.0
}
#endif

struct WindowSize {
    var width: CGFloat
    var height: CGFloat
}

enum WindowTypes: String, CaseIterable {
    case alert = "modalwindow"
    case preferences = "wreferenceswindow"
    case update = "changelogwindow"
    case onboarding = "onboardingwindow"
    case intro = "introwindow"
    case introControl = "introcontrolwindow"

    var size: WindowSize {
        switch self {
            case .alert: return .init(width: 420, height: 220)
            case .preferences: return .init(width: 500, height: 600)
            case .onboarding: return .init(width: 520, height: 580)
            case .update: return .init(width: 520, height: 420)
            case .intro: return .init(width: 0, height: 0) // Fullscreen
            case .introControl: return .init(width: 400, height: 250)
        }
    }
}

#if os(macOS)
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
#endif

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
class BBWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
#endif
