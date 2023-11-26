//
//  BBSettingsManager.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 11/21/23.
//

import Foundation
import Combine

class SettingsManager:ObservableObject {
    static var shared = SettingsManager()
    
    private var updates = Set<AnyCancellable>()

    public var enabledSoundEffects:SettingsSoundEffects {
        get {
            if let key = UserDefaults.main.object(forKey: SystemDefaultsKeys.enabledSoundEffects.rawValue) as? String {
                return SettingsSoundEffects(rawValue: key) ?? .enabled
                
            }
            
            return .enabled
        
        }
        
        set {
            if self.enabledSoundEffects == .disabled && newValue == .enabled {
                SystemSoundEffects.high.play(true)
                
            }
            
            UserDefaults.save(.enabledSoundEffects, value: newValue.rawValue)
            
        }
        
    }
    
}
