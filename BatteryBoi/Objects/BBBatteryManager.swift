//
//  BatteryManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import Foundation
import Combine
import EnalogSwift

#if os(macOS)
    import IOKit.pwr_mgt
    import IOKit.ps

#elseif os(iOS)
    import UIKit

#endif

enum BatteryWattageType {
    case current
    case max
    case voltage
    
}

enum BatteryThemalState {
    case optimal
    case suboptimal
    
}

enum BatteryCondition: String {
    case optimal = "Normal"
    case suboptimal = "Replace Soon"
    case malfunctioning = "Service Battery"
    case unknown = "Unknown"
    
}

struct BatteryCycleObject {
    var numerical:Int
    var formatted:String
    
    init(_ count:Int) {
        self.numerical = count
        
        if count > 999 {
            let divisor = pow(10.0, Double(1))
            let string = ((Double(count) / 1000.0) * divisor).rounded() / divisor

            self.formatted = "\(string)k"
            
        }
        else {
            self.formatted = "\(Int(count))"

        }
        
    }
    
}

struct BatteryMetricsObject {
    var cycles:BatteryCycleObject
    var heath:BatteryCondition
    
    init(cycles:String, health:String) {
        self.cycles = BatteryCycleObject(Int(cycles) ?? 0)
        self.heath = BatteryCondition(rawValue: health) ?? .optimal
        
    }
    
}

enum BatteryModeType:String {
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

enum BatteryChargingState:String {
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
    @Published var rate:BatteryEstimateObject? = nil
    @Published var saver:BatteryModeType = .unavailable

    #if os(macOS)
        @Published var metrics:BatteryMetricsObject? = nil
        @Published var thermal:BatteryThemalState = .optimal
    
    #endif
    
    private var counter:Int? = 0
    private var updates = Set<AnyCancellable>()

    init() {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            if self.counter == nil {
                self.powerUpdaterFallback()

            }
            
        }
        
        AppManager.shared.appTimer(1).dropFirst(5).sink { _ in
            self.powerStatus(true)
            self.counter = nil
            
        }.store(in: &updates)
        
        AppManager.shared.appTimer(6).sink { _ in
            self.remaining = self.powerRemaing
            self.counter = nil

        }.store(in: &updates)
        
        #if DEBUG && os(macOS)
            AppManager.shared.appTimer(90).sink { _ in
                self.powerThermalCheck()
             
            }.store(in: &updates)
        
        #endif
        
        AppManager.shared.appTimer(60).sink { _ in
            #if os(macOS)
                self.metrics = self.powerProfilerDetails
            
            #endif
            
            self.saver = self.powerSaveModeStatus
            self.counter = nil

        }.store(in: &updates)
        
        #if os(iOS)
            UIDevice.current.isBatteryMonitoringEnabled = true

            NotificationCenter.default.addObserver(self, selector: #selector(self.powerStateNotification(notification:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.powerStateNotification(notification:)), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        
        #endif
        
        self.powerStatus(true)

    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
    public func powerForceRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.powerStatus(true)
            
        }
        
        #if os(macOS)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.saver = self.powerSaveModeStatus
                self.metrics = self.powerProfilerDetails
                
            }
        
        #endif
        
    }
    
    private func powerUpdaterFallback() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let counter = self.counter {
                if counter.isMultiple(of: 1) {
                    self.powerStatus(true)
                    
                }
                
                if counter.isMultiple(of: 6) {
                    self.remaining = self.powerRemaing
                    
                }
                
            }
            
            self.counter = (self.counter ?? 0) + 1
            
        }
        
    }
    
    @objc private func powerStateNotification(notification: Notification) {
        self.powerStatus(true)
        
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
        #if os(macOS)
            let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
            let source = IOPSGetProvidingPowerSourceType(snapshot).takeRetainedValue()
            
            switch source as String == kIOPSACPowerValue {
                case true : return .charging
                case false : return .battery
                
            }
        
        #elseif os(iOS)
            switch UIDevice.current.batteryState {
                case .charging : return .charging
                case .full : return .charging
                default : return .battery
                
            }
        
        #endif
        
    }

    private var powerPercentage:Double {
        #if os(macOS)
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

        #elseif os(iOS)
            return Double(UIDevice.current.batteryLevel * 100)
        
        #endif
                
    }
    
    private var powerRemaing:BatteryRemaining? {
        #if os(macOS)
            if let response = ProcessManager.shared.processWithArguments("/bin/sh", arguments: ["-c", "pmset -g batt | grep -o '[0-9]\\{1,2\\}:[0-9]\\{2\\}'"]) {
                let trimmed = response.components(separatedBy: ":")
                
                if let hour = trimmed.map({ Int($0)}).first, let min = trimmed.map({ Int($0)}).last {
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
        
        #endif
        
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
        #if os(macOS)
            if let response = ProcessManager.shared.processWithArguments("/usr/bin/env", arguments:["bash", "-c", "pmset -g | grep lowpowermode"]) {
                
                if response.contains("lowpowermode") == true {
                    if response.contains("1") == true {
                        return .efficient
                        
                    }
                    else if response.contains("0") == true {
                        return .normal
                        
                    }
                    
                }
                
                
            }
        
            return .unavailable
        
        #elseif os(iOS)
            switch ProcessInfo.processInfo.isLowPowerModeEnabled {
                case true : return .efficient
                case false : return .normal
                
            }
            
        #endif
        
        
    }
        
    #if os(macOS)
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
    
    #endif
    
    #if os(macOS)
        private func powerThermalCheck() {
            if let response = ProcessManager.shared.processWithArguments("/usr/bin/env", arguments:["pmset", "-g", "therm"]) {
                let cores = self.powerCPUCores
                
                if let match = response.range(of: "CPU_Scheduler_Limit\\s+=\\s+(\\d+)", options: .regularExpression) {
                    let value = Int(response[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                    
                    if value < 100 {
                        self.thermal = .suboptimal
                        
                    }
                    
                }
                
            }
        
        }
    
    #endif

    #if os(macOS)
        private var powerProfilerDetails:BatteryMetricsObject? {
            if let response = ProcessManager.shared.processWithArguments("/usr/bin/env", arguments:["system_profiler", "SPPowerDataType"], whitespace: false) {
                let lines = response.split(separator: "\n")
                
                var cycles: String?
                var heath: String?
                
                for line in lines {
                    if line.contains("Cycle Count") {
                        cycles = String(line.split(separator: ":").last ?? "").trimmingCharacters(in: .whitespaces)
                        
                    }
                    
                    if line.contains("Condition") {
                        heath = String(line.split(separator: ":").last ?? "").trimmingCharacters(in: .whitespaces)
                        
                    }
                    
                    if let cycles = cycles, let heath = heath {
                        return .init(cycles: cycles, health: heath)
                        
                    }
                    
                }
                
            }
            
            return nil

        }
    
    #endif
    
    #if os(macOS)
        private var powerCPUCores:Int {
            if let response = ProcessManager.shared.processWithArguments("/usr/bin/env", arguments:["sysctl", "-n", "hw.physicalcpu"], whitespace: false) {
                if let cores = Int(response.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return cores
                    
                }
                
            }
        
            return 1
            
        }

    #endif
    
    #if os(macOS)
        private func powerWattage(_ type: BatteryWattageType) -> Int? {
            var arguments:[String] = []
            
            switch type {
                case .current: arguments = ["-c", "ioreg -l | grep CurrentCapacity | awk '{print $5}'"]
                case .max: arguments = ["-c", "ioreg -l | grep MaxCapacity | awk '{print $5}'"]
                case .voltage: arguments = ["-c", "ioreg -l | grep Voltage | awk '{print $5}'"]
                
            }
            
            if let response = ProcessManager.shared.processWithArguments("/bin/sh", arguments: arguments) {
                return Int(response.trimmingCharacters(in: .whitespacesAndNewlines))

            }
        
            return nil
            
        }
    
    #endif
    
    #if os(macOS)
        public func powerHourWattage() -> Double? {
            if let mAh = self.powerWattage(.max), let mV = self.powerWattage(.voltage) {
                print("Max" ,mAh)
                print("Voltage" ,mV)

                return (Double(mAh) / 1000.0) * (Double(mV) / 1000.0)
                
            }
            
            return nil
            
        }
    
    #endif
    
//    func setSMCByte(key: String, value: UInt8) {
//           do {
//               try SMCKit.open()
//           } catch {
//               print(error)
//               exit(EX_UNAVAILABLE)
//           }
//           let smcKey = SMCKit.getKey(key, type: DataTypes.UInt8)
//           let bytes: SMCBytes = (value, UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
//           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
//           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
//           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
//           UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
//           UInt8(0), UInt8(0))
//           
//           if(self.modifiedKeys[key] == nil){
//               readSMCByte(key: key) { (originalValue) in
//                   self.modifiedKeys[key] = originalValue
//                   _ = try? SMCKit.writeData(smcKey, data: bytes)
//               }
//           }
//           else{
//               _ = try? SMCKit.writeData(smcKey, data: bytes)
//           }
//
//           
//       }
    
}
