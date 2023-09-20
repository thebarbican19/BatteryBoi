//
//  BBTriggerClass.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/1/23.
//

import Foundation
import Combine

class TriggerClass {
    static var shared = TriggerClass()
    
    private var updates = Set<AnyCancellable>()

    init() {
        BatteryManager.shared.$charging.dropFirst().removeDuplicates().sink { charging in
            
        }.store(in: &updates)

    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
    public func triggerPercent(_ percent:Double) {
        // TBC
        
    }
    
    public func triggerState(_ state:HUDAlertTypes, device:BluetoothObject) {
        if state.trigger == false {
            fatalError("This is not a Trigger State")
            
        }
        
        // TBC
        
    }
    
}
