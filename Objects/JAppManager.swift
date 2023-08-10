//
//  DAppManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/9/23.
//

import Foundation
import EnalogClient
import Combine

class AppManager:ObservableObject {
    static var shared = AppManager()
    
    @Published var style:BatteryStyle
    @Published var estimate:SettingsStateValue

    private var updates = Set<AnyCancellable>()

    init() {
        self.style = SettingsManager.shared.enabledStyle
        self.estimate = SettingsManager.shared.enabledEstimateStatus

        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            switch key {
                case .enabledStyle : self.style = SettingsManager.shared.enabledStyle
                case .enabledEstimate : self.estimate = SettingsManager.shared.enabledEstimateStatus
                default : break
                
            }
            
        }.store(in: &updates)
        
    }
    
    public var appInstalled:Date {
        if let date = UserDefaults.main.object(forKey: SystemDefaultsKeys.versionInstalled.rawValue) as? Date {
            return date
            
        }
        else {
            UserDefaults.save(.versionInstalled, value: Date())
            
            if #available(macOS 12.0, *) {
                EnalogManager.main.ingest(SystemEvents.userInstalled, description: "Installed App")
                
            }

            return Date()
            
        }
        
    }
    
}
