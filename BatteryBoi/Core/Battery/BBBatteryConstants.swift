//
//  BBBatteryConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation
import SwiftData

enum BatteryTriggerType {
    case lowpower
    case limit
}

enum BatteryChargingState: String {
    case charging
    case battery

    public var charging: Bool {
        switch self {
            case .charging: return true
            case .battery: return false
        }
    }

    public func progress(_ percent: Int, width: CGFloat) -> CGFloat {
        if percent > 0 && percent < 10 {
            return min(CGFloat(10 / 100) * (width - 2.6), (width - 2.6))
        }
        else if percent >= 90 && percent < 100 {
            return min(CGFloat(90 / 100) * (width - 2.6), (width - 2.6))
        }
        else {
            return min(CGFloat(percent / 100) * (width - 2.6), (width - 2.6))
        }
    }
}

enum BatteryModeType: String, CaseIterable {
    case normal
    case efficient
    case unavailable

    var flag: Bool {
        switch self {
            case .normal: return false
            case .efficient: return true
            case .unavailable: return false
        }
    }
}

enum BatteryThemalState {
    case optimal
    case suboptimal

    var flag: Bool {
        switch self {
            case .optimal: return false
            case .suboptimal: return true
        }
    }

    var warning: ProcessResponseHeaderType {
        switch self {
            case .optimal: return .normal
            case .suboptimal: return .error
        }
    }
}

enum BatteryHealthState: String {
    case optimal = "Normal"
    case suboptimal = "Suboptimal"
    case malfunctioning = "Service Battery"
    case unknown = "Unknown"

    var warning: ProcessResponseHeaderType {
        switch self {
            case .optimal: return .sucsess
            case .suboptimal: return .warning
            case .unknown: return .normal
            default: return .error
        }
    }
}

struct BatteryInformationObject {
    var available: Double
    var capacity: Double
    var charger: String?
    var manufacturer: String?
    var accumulated: Double?
    var serial: String?
    var watts: Double?
    var powered: Bool? = nil
    var batteries: Int? = nil

    init?(available: Double?, capacity: Double?, voltage: Double?, charger: String?, manufacturer: String?, accumulated: Double?, serial: String?, watts: Double?) {
        if let available = available, let capacity = capacity {
            self.available = available
            self.capacity = capacity
            self.manufacturer = manufacturer?.replacingOccurrences(of: ")", with: "")
            self.charger = charger
            self.serial = serial
            self.watts = watts

            if let accumulated = accumulated {
                self.accumulated = accumulated / 3600000
            }
        }
        else {
            return nil
        }
    }
}

struct BatteryThemalObject: Equatable {
    var state: BatteryThemalState
    var formatted: String
    var value: Double

    init(_ value: Double) {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitStyle = .medium

        let temperature = Measurement(value: value, unit: UnitTemperature.fahrenheit)

        self.value = value
        self.formatted = formatter.string(from: temperature)
        self.state = value > 95 ? .suboptimal : .optimal
    }
}

struct BatteryHealthObject {
    var state: BatteryHealthState
    var capacity: Double
    var available: Double
    var percentage: Double
    var cycles: Int

    init?(available: Double?, capacity: Double?, cycles: Int?) {
        if let available = available, let capacity = capacity, let cycles = cycles {
            self.capacity = capacity
            self.available = available
            self.percentage = available / capacity * 100
            self.cycles = (cycles / (100 - Int(self.percentage))) * (Int(self.percentage) - 50)

            switch self.percentage {
                case 81...: self.state = .optimal
                case 65...80: self.state = .suboptimal
                default: self.state = .malfunctioning
            }
        }
        else {
            return nil
        }
    }
}

struct BatteryRemaining: Equatable {
    static func == (lhs: BatteryRemaining, rhs: BatteryRemaining) -> Bool {
        return lhs.date == rhs.date
    }

    var date: Date
    var hours: Int? = nil
    var minutes: Int? = nil
    var formatted: String?

    init(hour: Int, minute: Int) {
        self.hours = hour
        self.minutes = minute
        self.date = Date(timeIntervalSinceNow: 60 * 2)

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        if let date = Calendar.current.date(byAdding: components, to: Date()) {
            let units = Calendar.current.dateComponents([.minute, .hour], from: Date(), to: date)

            if let hours = units.hour, let minutes = units.minute {
                if hours == 0 && minutes == 0 {
                    self.formatted = "AlertDeviceCalculatingTitle".localise()
                }
                else if hours != 0 && minutes != 0 {
                    self.formatted = "\("TimestampHourFullLabel".localise([hours]))  \("TimestampMinuteFullLabel".localise([minutes]))"
                }
                else if hours == 0 {
                    self.formatted = "TimestampMinuteFullLabel".localise([minutes])
                }
                else if minute == 0 {
                    self.formatted = "TimestampHourFullLabel".localise([hour])
                }
            }

            self.date = date
        }
    }
}

struct BatteryEstimateObject {
    var timestamp: Date
    var percent: Double

    init(_ percent: Double) {
        self.timestamp = Date()
        self.percent = percent
    }
}

@Model
final class BatteryEntry {
    var id: UUID? = UUID()
    var timestamp: Date? = Date()
    var percentage: Int? = 0
    var charging: Bool? = false
    var mode: String? = ""

    init(percentage: Int, isCharging: Bool, mode: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.percentage = percentage
        self.charging = isCharging
        self.mode = mode
    }
}
