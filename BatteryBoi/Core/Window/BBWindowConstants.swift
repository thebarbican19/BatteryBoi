//
//  BBWindowConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation
import SwiftUI
import Cocoa
import CoreGraphics

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
    case overlay = "overlaywindow"

    var size: WindowSize {
        switch self {
            case .alert: return .init(width: 420, height: 220)
            case .preferences: return .init(width: 500, height: 600)
            case .onboarding: return .init(width: 520, height: 580)
            case .update: return .init(width: 520, height: 420)
            case .overlay: return .init(width: 0, height: 0) // Fullscreen
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

@objc(BBWindow)
class BBWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
