//
//  SettingsManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/5/23.
//

import Foundation
import Combine
import LaunchAtLogin

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
            if UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledLogin.rawValue) == nil {
                return .undetermined
                
            }
            
            return LaunchAtLogin.isEnabled ? .enabled : .disabled
            
        }
        
        set {
            if self.enabledAutoLaunch != .undetermined {
                LaunchAtLogin.isEnabled = newValue.enabled
                
                UserDefaults.save(.enabledLogin, value: newValue.enabled)
                
            }
           
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

}
