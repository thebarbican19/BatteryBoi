//
//  BBCloudModels.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/27/23.
//

import Foundation
import CloudKit
import SwiftData

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

public enum DeviceState: String, Codable {
    case discovered = "discovered"
    case added = "added"
    case ignored = "ignored"

    public var label: String {
        switch self {
        case .discovered: return "Discovered"
        case .added: return "Added"
        case .ignored: return "Ignored"
        }
    }

    public var tint: String {
        switch self {
        case .discovered: return "orange"
        case .added: return "green"
        case .ignored: return "red"
        }
    }

    public func next() -> DeviceState {
        switch self {
        case .discovered: return .added
        case .added: return .ignored
        case .ignored: return .added
        }
    }
}

@Model
public final class DevicesObject {
    public var id: UUID? = UUID()
    public var name: String? = ""
    public var model: String? = ""
    public var type: String? = ""
    public var subtype: String? = ""
    public var product: String? = ""
    public var vendor: String? = ""
    public var address: String? = ""
    public var serial: String? = ""
    public var os: String? = ""
    public var apperance: String? = ""
    public var owner: UUID? = nil
    public var addedOn: Date? = Date()
    public var refreshedOn: Date? = Date()
    public var order: Int? = 0
    public var primary: Bool? = false
    public var notifications: Bool? = false
    public var findmy: Bool? = false
    public var state: String? = DeviceState.discovered.rawValue
    @Relationship(deleteRule: .cascade, inverse: \BatteryObject.device) public var events: [BatteryObject]? = []

    public init(id: UUID? = UUID(), name: String? = "", model: String? = "", type: String? = "", subtype: String? = "", product: String? = "", vendor: String? = "", address: String? = "", serial: String? = "", os: String? = "", apperance: String? = "", owner: UUID? = nil, addedOn: Date? = Date(), refreshedOn: Date? = Date(), order: Int? = 0, primary: Bool? = false, notifications: Bool? = false, findmy: Bool? = false, state: DeviceState = .discovered) {
        self.id = id
        self.name = name
        self.model = model
        self.type = type
        self.subtype = subtype
        self.product = product
        self.vendor = vendor
        self.address = address
        self.serial = serial
        self.os = os
        self.apperance = apperance
        self.owner = owner
        self.addedOn = addedOn
        self.refreshedOn = refreshedOn
        self.order = order
        self.primary = primary
        self.notifications = notifications
        self.findmy = findmy
        self.state = state.rawValue
    }
}

@Model
public final class BatteryObject {
    public var id: UUID? = UUID()
    public var created: Date? = Date()
    public var percent: Int? = 0
    public var state: String? = ""
    public var mode: String? = ""
    public var cycles: Int? = 0
    public var temprature: Int? = 0
    public var os: Int? = 0
    public var session: UUID? = nil
    @Relationship(deleteRule: .nullify) public var device: DevicesObject? = nil
    @Relationship(deleteRule: .nullify, inverse: \AlertsObject.event) public var alert: AlertsObject? = nil

    public init(id: UUID? = UUID(), created: Date? = Date(), percent: Int? = 0, state: String? = "", mode: String? = "", cycles: Int? = 0, temprature: Int? = 0, os: Int? = 0, session: UUID? = nil) {
        self.id = id
        self.created = created
        self.percent = percent
        self.state = state
        self.mode = mode
        self.cycles = cycles
        self.temprature = temprature
        self.os = os
        self.session = session
    }
}

@Model
public final class AlertsObject {
    public var id: UUID? = UUID()
    public var type: String? = ""
    public var owner: UUID? = nil
    public var triggeredOn: Date? = nil
    public var viewed: Date? = nil
    public var local: Bool? = false
    @Relationship(deleteRule: .nullify) public var event: BatteryObject? = nil

    public init(id: UUID? = UUID(), type: String? = "", owner: UUID? = nil, triggeredOn: Date? = nil, viewed: Date? = nil, local: Bool? = false) {
        self.id = id
        self.type = type
        self.owner = owner
        self.triggeredOn = triggeredOn
        self.viewed = viewed
        self.local = local
    }
}

@Model
public final class PushObject {
    public var id: UUID? = UUID()
    public var type: String? = ""
    public var percent: Int? = 0
    public var custom: Bool? = false
    public var addedOn: Date? = Date()
    public var updatedOn: Date? = Date()

    public init(id: UUID? = UUID(), type: String? = "", percent: Int? = 0, custom: Bool? = false, addedOn: Date? = Date(), updatedOn: Date? = Date()) {
        self.id = id
        self.type = type
        self.percent = percent
        self.custom = custom
        self.addedOn = addedOn
        self.updatedOn = updatedOn
    }
}
