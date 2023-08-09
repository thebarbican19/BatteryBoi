//
//  DAppManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/9/23.
//

import Foundation
import EnalogClient

class AppManager:ObservableObject {
    static var shared = AppManager()
    
    init() {
        print("App Installed: \(self.appInstalled)")
        
    }
    
    public var appInstalled:Date {
        if let date = UserDefaults.main.object(forKey: SystemDefaultsKeys.versionInstalled.rawValue) as? Date {
            return date
            
        }
        else {
            UserDefaults.save(.versionInstalled, value: Date())
            
            EnalogManager.main.ingest(SystemEvents.userInstalled, description: "Installed App")

            return Date()
            
        }
        
    }
    
}
