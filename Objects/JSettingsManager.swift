//
//  SettingsManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/5/23.
//

import Foundation
import Combine
import AppKit
import SwiftUI

#if !OLDER_MACOS
    import LaunchAtLogin
#endif

enum SettingsStateValue:String {
    case enabled
    case disabled
    case undetermined
    case restricted
    
    var enabled:Bool {
        switch self {
            case .disabled : return false
            default : return true
            
        }
        
    }
    
    var boolean:Bool {
        switch self {
            case .enabled : return true
            default : return false
            
        }
        
    }
    
    var title:String {
        switch self {
            case .enabled : return "Enabled"
            case .disabled : return "Disabled"
            case .undetermined : return "Not Set"
            case .restricted : return "Restricted"

        }
        
    }
    
}

class SettingsManager:ObservableObject {
    static var shared = SettingsManager()
    
    public var enabledAutoLaunch:SettingsStateValue {
        get {
            #if !OLDER_MACOS
                if UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledLogin.rawValue) == nil {
                    return .undetermined
                    
                }
                
                return LaunchAtLogin.isEnabled ? .enabled : .disabled
                
            #endif

            return .restricted
            
        }
        
        set {
            #if !OLDER_MACOS
                if self.enabledAutoLaunch != .undetermined {
                    LaunchAtLogin.isEnabled = newValue.enabled
                    
                    UserDefaults.save(.enabledLogin, value: newValue.enabled)
                    
                }
                
            #endif

           
        }
        
    }
    
    public var enabledEstimateStatus:SettingsStateValue {
        get {
            if UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledEstimate.rawValue) == nil {
                return .restricted
                
            }
            else {
                switch UserDefaults.main.bool(forKey: SystemDefaultsKeys.enabledEstimate.rawValue) {
                    case true : return .enabled
                    case false : return .disabled
                    
                }
                
            }
            
        }
        
        set {
            if self.enabledEstimateStatus != newValue {
                UserDefaults.save(.enabledEstimate, value: newValue.enabled)
                
            }
            
        }
        
    }
    
    public var enabledMarqueeAnimation:Bool {
        get {
            UserDefaults.main.bool(forKey: SystemDefaultsKeys.enabledMarquee.rawValue)
            
        }
        
        set {
            if self.enabledMarqueeAnimation != newValue {
                UserDefaults.save(.enabledMarquee, value: newValue)
                
            }
            
        }
        
    }
    
    public var enabledStyle:BatteryStyle {
        get {
            if let style = UserDefaults.main.string(forKey: SystemDefaultsKeys.enabledStyle.rawValue) {
                return BatteryStyle(rawValue: style) ?? .chunky
                
            }

            return .chunky
            
        }
        
        set {
            if self.enabledStyle != newValue {
                UserDefaults.save(.enabledMarquee, value: newValue)
                
            }
            
        }
        
    }

}
