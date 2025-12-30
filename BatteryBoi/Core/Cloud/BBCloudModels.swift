//
//  BBCloudModels.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/27/23.
//

import Foundation
import CloudKit
import CoreData

#if os(iOS)
import UIKit
import ActivityKit

struct CloudNotifyAttributes: ActivityAttributes {
    let device: String

    public struct ContentState: Hashable, Codable {
        var battery: Int
        var charging: Bool
        var timestamp: Date
    }

}
#endif
