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

struct WindowSize {
    var width:CGFloat
    var height:CGFloat
    
}

enum WindowTypes:String,CaseIterable {
    case about = "About_Window"
    case preferences = "Preferences_Window"

    var size:WindowSize {
        switch self {
            case .preferences : return .init(width: 800, height: 480)
            case .about: return .init(width: 500, height: 580)
            
        }
        
    }
    
    var host:NSView {
        switch self {
            case .about : return NSHostingController(rootView: TipView()).view
            case .preferences : return NSHostingController(rootView: TipView()).view
          
        }
        
    }
    
    var title:String {
        switch self {
            case .about:return "About"
            case .preferences:return "Preferences"

        }
        
    }
    
}

class WindowManager: ObservableObject {
    static var shared = WindowManager()
            
    @Published var active:WindowTypes? = nil
    
    public func windowIsVisible(_ type:WindowTypes) -> Bool {
        if let window = self.windowExists(type) {
            if CGFloat(window.alphaValue) > 0.5 {
                return true
                
            }
            
        }
        
        return false
        
    }
    
    public func windowOpen(_ type:WindowTypes) {
        if let window = self.windowExists(type) {
            window.contentView = type.host
     
            DispatchQueue.main.async {
                window.makeKeyAndOrderFront(nil)
                    
            }
                        
        }

    }

    public func windowClose(_ type:WindowTypes) {
        if let window = NSApplication.shared.windows.filter({$0.title == type.rawValue}).first {
            NSAnimationContext.runAnimationGroup({ (context) -> Void in
                context.duration = 1.0
                
                window.animator().alphaValue = 0.0;

                
            }) {
                window.close()
      
            }
            
        }

    }
    
    private func windowDefault(_ type:WindowTypes) -> NSWindow? {
        let bounds = WindowScreenSize()
        var window:NSWindow?
        
        window = NSWindow()
        window?.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window?.level = .normal
        window?.contentView?.translatesAutoresizingMaskIntoConstraints = false
        window?.center()
        window?.title = type.rawValue
        window?.isMovableByWindowBackground = true
        window?.backgroundColor = .clear
        window?.setFrame(NSRect(x: (bounds.width / 2) - (type.size.width / 2), y: (bounds.height / 2) - (type.size.height / 2), width: type.size.width, height: type.size.height), display: false)
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.toolbarStyle = .unifiedCompact
        window?.isReleasedWhenClosed = false
        window?.alphaValue = 0.0
        
        print("type.size.width" ,type.size.width)
                     
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = 0.2
            
            window?.animator().alphaValue = 1.0
            
        }, completionHandler: nil)
        
        return window
 
    }
    
    private func windowExists(_ type: WindowTypes) -> NSWindow? {
        if let window = NSApplication.shared.windows.first(where: { WindowTypes(rawValue: $0.title) == type }) {
            return window
            
        }
        else {
            return self.windowDefault(type)
            
        }
                        
    }

}
