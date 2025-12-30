//
//  BBStatsConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation

enum StatsNotificationType: String {
    case alert
    case background
}

struct StatsIcon {
    var name: String
    var system: Bool
}

enum StatsStateType: String {
    case charging
    case battery
    case overheating
    case depleted
    case connected
    case disconnected
}

struct StatsDisplayObject {
    var standard: String?
    var overlay: String?
}
