//
//  BBStatsModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/30/23.
//

import Foundation

enum StatsActivityNotificationType:String {
    case alert
    case background
    case none
    
}

struct StatsIcon {
    var name:String
    var system:Bool
    
}

enum StatsStateType:String {
    case charging
    case battery
    case depleted
    case connected
    case disconnected
    
}

struct StatsDisplayObject {
    var standard:String?
    var overlay:String?
    
}
