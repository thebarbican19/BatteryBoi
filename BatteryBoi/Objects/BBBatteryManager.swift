//
//  BatteryManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import Foundation
import Combine
import IOKit.ps
import EnalogSwift

enum BatteryModeType {
    case normal
    case efficient
    case unavailable
    
    var flag:Bool {
        switch self {
            case .normal : return false
            case .efficient : return true
            case .unavailable : return false
            
        }
        
    }
    
}

enum BatteryChargingState {
    case charging
    case battery
    
    public var charging:Bool {
        switch self {
            case .charging : return true
            case .battery : return false
            
        }
        
    }
    
    public func progress(_ percent:Double, width:CGFloat) -> CGFloat {
        if self == .charging {
            return min(100 * (width - 2.6), (width - 2.6))
            
        }
        else {
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
    
}

struct BatteryCharging:Equatable {
    var state:BatteryChargingState
    var started:Date?
    var ended:Date?
    
    init(_ charging:BatteryChargingState) {
        self.state = charging
        
        switch charging {
            case .charging : self.started = Date()
            case .battery : self.ended = Date()

        }
        
    }
    
}

struct BatteryRemaining:Equatable {
    static func == (lhs: BatteryRemaining, rhs: BatteryRemaining) -> Bool {
        return lhs.date == rhs.date
        
    }
    
    var date:Date
    var hours:Int? = nil
    var minutes:Int? = nil
    var formatted:String?
    
    init(hour: Int, minute:Int) {
        self.hours = hour
        self.minutes = minute
        self.date = Date(timeIntervalSinceNow: 60*2)

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
    var timestamp:Date
    var percent:Double
    
    init(_ percent: Double) {
        self.timestamp = Date()
        self.percent = percent
        
    }
    
}

class BatteryManager:ObservableObject {
    static var shared = BatteryManager()
    
    @Published var charging:BatteryCharging = .init(.battery)
    @Published var percentage:Double = 100
    @Published var remaining:BatteryRemaining? = nil
    @Published var mode:Bool = false
    @Published var saver:BatteryModeType = .unavailable
    @Published var rate:BatteryEstimateObject? = nil
    
    private var updates = Set<AnyCancellable>()

    init() {
        AppManager.shared.appTimer(1).dropFirst(5).sink { _ in
            self.powerStatus(true)
            
        }.store(in: &updates)
        
        AppManager.shared.appTimer(6).sink { _ in
            self.remaining = self.powerRemaing

        }.store(in: &updates)

        AppManager.shared.appTimer(60).sink { _ in
            self.saver = self.powerSaveModeStatus

        }.store(in: &updates)
        
        self.powerStatus(true)
                
        
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
    private func powerStatus(_ force:Bool = false) {
        if force == true {
            self.percentage = self.powerPercentage

            if self.powerCharging != self.charging.state {
                self.charging = .init(self.powerCharging)
                
            }
            
        }
        
    }
    
    private var powerCharging:BatteryChargingState {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let source = IOPSGetProvidingPowerSourceType(snapshot).takeRetainedValue()
        
        switch source as String == kIOPSACPowerValue {
            case true : return .charging
            case false : return .battery
            
        }
        
    }

    private var powerPercentage:Double {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                
                if description["Type"] as? String == kIOPSInternalBatteryType {
                    return description[kIOPSCurrentCapacityKey] as? Double ?? 0.0
                    
                }
                
            }
            
        }
        
        return 100.0
        
    }
    
    private var powerRemaing:BatteryRemaining? {
        print("Battery Power Remaining Function Polled at \(Date())")

        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", "pmset -g batt | grep -o '[0-9]\\{1,2\\}:[0-9]\\{2\\}'"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ":") {
            if let hour = output.map({ Int($0)}).first, let min = output.map({ Int($0)}).last {
                if let hour = hour, let minute = min {
                    self.powerDepetionAverage =  (Double(hour) * 60.0 * 60.0) + (Double(minute) * 60.0)

                    return .init(hour: hour, minute: minute)

                }
                else if let rate = self.powerDepetionAverage {
                    let date = Date().addingTimeInterval(rate * self.percentage)
                    let components = Calendar.current.dateComponents([.hour, .minute], from: Date(), to: date)
                    
                    return .init(hour: components.hour ?? 0, minute: components.minute ?? 0)

                }
                
                return .init(hour: 0, minute: 0)
                
            }

        }
        
        return nil
        
    }
    
    public var powerUntilFull:Date? {
        var seconds = 180.0
        let remainder = 100 - self.percentage

        if self.charging.state == .charging {
            if let exists = self.rate {
                if self.percentage > exists.percent {
                    seconds = Date().timeIntervalSince(exists.timestamp)

                    UserDefaults.save(.batteryUntilFull, value: seconds)
                    
                }
                
            }
            
            self.rate = .init(percentage)

        }
        
        return Date(timeIntervalSinceNow: Double(seconds) * Double(remainder))

    }
    
    private var powerDepetionAverage:Double? {
        get {
            if let averages = UserDefaults.main.object(forKey: SystemDefaultsKeys.batteryDepletionRate.rawValue) as? Array<Double> {
                
                if averages.count > 0 {
                    return averages.reduce(0.0, +) / Double(averages.count)

                }
                
            }
            
            return nil
            
        }
        
        set {
            if let seconds = newValue {
                let averages = UserDefaults.main.object(forKey: SystemDefaultsKeys.batteryDepletionRate.rawValue) as? Array<Double> ?? Array<Double>()
                
                if averages.contains(seconds / self.percentage) == false && self.charging.state == .battery {
                    if (seconds / self.percentage) > 0.0 {
                        var list = Array(averages.suffix(15))
                        list.append(seconds / self.percentage)
                        
                        UserDefaults.save(.batteryDepletionRate, value: list)
                        
                    }

                }
                
            }

        }
        
    }
    
    private var powerSaveModeStatus:BatteryModeType {
        print("Battery Power Saving Function Polled at \(Date())")

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["bash", "-c", "pmset -g | grep lowpowermode"]

        let pipe = Pipe()
        task.standardOutput = pipe
        
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        if let output = output?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if output.contains("lowpowermode") == true {
                if output.contains("1") == true {
                    return .efficient

                }
                else if output.contains("0") == true {
                    return .normal

                }
                
            }
            
        }
                
        return .unavailable
        
    }
    
    public func powerSaveMode() {
        if self.saver != .unavailable {
            let command = "do shell script \"pmset -c lowpowermode \(self.saver.flag ? 0 : 1)\" with administrator privileges"
            
            if let script = NSAppleScript(source:command) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                
                DispatchQueue.main.async {
                    self.saver = self.powerSaveModeStatus
                    
                }
                
            }
            
        }
                
    }
    
}
