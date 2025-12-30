//
//  BBUpdateConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation

struct UpdateVersionObject: Codable {
    var formatted: String
    var numerical: String
}

struct UpdatePayloadObject: Equatable {
    static func == (lhs: UpdatePayloadObject, rhs: UpdatePayloadObject) -> Bool {
        return lhs.id == rhs.id
    }

    var id: String
    var name: String
    var version: UpdateVersionObject
    var binary: String?
    var cached: Bool?
    var ignore: Bool = false
}

enum UpdateStateType {
    case idle
    case checking
    case updating
    case failed
    case completed

    public func subtitle(_ last: Date?, version: String? = nil) -> String {
        switch self {
            case .idle: return "UpdateStatusIdleLabel".localise([last?.formatted ?? "TimestampNeverLabel".localise()])
            case .checking: return "UpdateStatusCheckingLabel".localise()
            case .updating: return "UpdateStatusNewLabel".localise([version ?? ""])
            case .failed: return "UpdateStatusEmptyLabel".localise()
            case .completed: return "UpdateStatusEmptyLabel".localise()
        }
    }
}
