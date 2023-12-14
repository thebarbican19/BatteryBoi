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
    import IOKit

#elseif os(iOS)
    import UIKit

#endif

enum BatteryTriggerType {
    case lowpower
    case limit
    
}

struct BatteryInformationObject {
    var available:Double
    var capacity:Double
    var charger:String?
    var manufacturer:String?
    var accumulated:Double?
    var serial:String?

    init?(available:Double?, capacity:Double?, voltage:Double?, charger:String?, manufacturer:String?, accumulated:Double?, serial:String?) {
        if let available = available, let capacity = capacity {
            self.available = available
            self.capacity = capacity
            self.manufacturer = manufacturer?.replacingOccurrences(of: ")", with: "")
            self.charger = charger
            self.serial = serial

            if let accumulated = accumulated {
                self.accumulated = accumulated / 3600000 // (kWh)

            }

        }
        else {
            return nil
            
        }
        
    }
    
}

struct BatteryThemalObject {
    var state:BatteryThemalState
    var formatted:String
    var value:Double

    init(_ value:Double) {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitStyle = .medium
        
        let temperature = Measurement(value: value, unit: UnitTemperature.fahrenheit)
                
        self.value = value
        self.formatted = formatter.string(from: temperature)
        self.state = value > 95 ? .suboptimal : .optimal
        
    }
    
}

enum BatteryThemalState {
    case optimal
    case suboptimal
    
    var flag:Bool {
        switch self {
            case .optimal : return false
            case .suboptimal : return true
            
        }
        
    }
    
    #if os(macOS)
        var warning:ProcessResponseHeaderType {
            switch self {
                case .optimal : return .normal
                case .suboptimal : return .error
                
            }
            
        }
    
    #endif
    
}

struct BatteryHealthObject {
    var state:BatteryHealthState
    var capacity:Double
    var available:Double
    var percentage:Double
    var cycles:Int
    
    init?(available:Double?, capacity:Double?, cycles:Int?) {
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

enum BatteryHealthState: String {
    case optimal = "Normal"
    case suboptimal = "Suboptimal"
    case malfunctioning = "Service Battery"
    case unknown = "Unknown"
    
    #if os(macOS)
        var warning:ProcessResponseHeaderType {
            switch self {
                case .optimal : return .sucsess
                case .suboptimal : return .warning
                case .unknown : return .normal
                default : return .error
                
            }
            
        }
    
    #endif
        
}

enum BatteryModeType:String,CaseIterable {
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
    
    public func progress(_ percent:Int, width:CGFloat) -> CGFloat {
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

    @Published var charging:BatteryChargingState = .charging
    @Published var percentage:Int = 100
    @Published var remaining:BatteryRemaining? = nil
    @Published var mode:BatteryModeType = .unavailable

    #if os(macOS)
        @Published var health:BatteryHealthObject? = nil
        @Published var temperature:BatteryThemalObject = .init(20)
        @Published var info:BatteryInformationObject? = nil
    
    #endif
    
    #if os(macOS)
        private var connection: io_connect_t = 0
    
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
            self.powerStatus(true)
            self.counter = nil

        }.store(in: &updates)
        
        #if DEBUG && os(macOS)
            AppManager.shared.appTimer(90).sink { _ in
                self.powerTempratureCheck()
             
            }.store(in: &updates)
        
        #endif
        
        AppManager.shared.appTimer(60).sink { _ in
            #if os(macOS)
                self.powerMetrics()

            #endif
            
            self.counter = nil

        }.store(in: &updates)
        
        $percentage.removeDuplicates().receive(on: DispatchQueue.global()).sink() { newValue in
            switch BatteryManager.shared.charging {
                case .battery : AppManager.shared.appStoreEvent(.disconnected, device: nil)
                case .charging : AppManager.shared.appStoreEvent(.charging, device: nil)
                
            }

        }.store(in: &updates)
        
        $charging.removeDuplicates().receive(on: DispatchQueue.global()).sink() { newValue in
            switch newValue {
                case .battery : AppManager.shared.appStoreEvent(.disconnected, device: nil)
                case .charging : AppManager.shared.appStoreEvent(.connected, device: nil)

            }

        }.store(in: &updates)
        
        #if os(iOS)
            UIDevice.current.isBatteryMonitoringEnabled = true

            NotificationCenter.default.addObserver(self, selector: #selector(self.powerStateNotification(notification:)), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.powerStateNotification(notification:)), name: UIDevice.batteryStateDidChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.powerStateNotification(notification:)), name: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil)

        
        #endif
        
        self.powerForceRefresh()
        
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
    public func powerForceRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.powerStatus(true)
            self.powerEfficiencyMode()
           
            #if os(macOS)
                self.powerTempratureCheck()
                self.powerMetrics()
            
            #endif
        }
        
    }
    
    public func powerEfficiencyMode(_ force:BatteryModeType? = nil) {
        #if os(macOS)
            if let context = ProcessManager.shared.processHelperContext() {
                if let update = force {
                    context.helperToggleLowPower(update == .efficient ? .enabled : .disabled) { state in
                        DispatchQueue.main.async {
                            switch state {
                                case .enabled : self.mode = .efficient
                                default : self.mode = .normal

                            }
                                                        
                        }
                        
                    }
                    
                }
                else {
                    context.helperPowerMode { state in
                        DispatchQueue.main.async {
                            switch state {
                                case .enabled : self.mode = .efficient
                                default : self.mode = .normal
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
        
        #else
            self.mode = ProcessInfo.processInfo.isLowPowerModeEnabled ? .efficient : .normal

        #endif
    
    }
    
    public func powerTrigger(_ type:BatteryTriggerType, value:Int = 0) {
        #warning("To Build Functionality")
        
    }
    
    private func powerUpdaterFallback() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let counter = self.counter {
                if counter.isMultiple(of: 1) {
                    self.powerStatus(true)
                    
                }
                
                if counter.isMultiple(of: 6) {
                    //self.remaining = self.powerRemaing
                    
                }
                
            }
            
            self.counter = (self.counter ?? 0) + 1
            
        }
        
    }
    
    @objc private func powerStateNotification(notification: Notification) {
        self.powerForceRefresh()
        
    }
    
    private func powerStatus(_ force:Bool = false) {
        if force == true {
            self.percentage = self.powerPercentage

        }
        
    }
    
    private func powerCharging() {
        #if os(macOS)
            if let battery = try? SMCKit.batteryInformation() {
                DispatchQueue.main.async {
                    switch battery.isCharging {
                        case true : self.charging = .charging
                        case false : self.charging =  .battery
                        
                    }
               
                }
                
            }

            self.charging = .charging
        
        #elseif os(iOS)
            switch UIDevice.current.batteryState {
                case .charging : self.charging = .charging
                case .full : self.charging = .charging
                default : self.charging = .battery
                
            }
        
        #endif
        
    }

    private var powerPercentage:Int {
        #if os(macOS)
            let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
            let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
            for source in sources {
                if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                    
                    if description["Type"] as? String == kIOPSInternalBatteryType {
                        return description[kIOPSCurrentCapacityKey] as? Int ?? Int(0.0)
                        
                    }
                    
                }
                
            }
        
            return 100

        #elseif os(iOS)
            return Int(UIDevice.current.batteryLevel * 100)
        
        #endif
                
    }
        
    public var powerUntilFull:Date? {
        return Date()
        
    }
    
    #if os(macOS)
        private func powerTempratureCheck() {
            if let value = self.powerReadData("TB0T", type: DataTypes.UInt16) {
                DispatchQueue.main.async {
                    self.temperature = .init(Double(value / 100))
                   
                }
                
            }
            
        }
           
    #endif
    
    #if os(macOS)
        private func powerMetrics() {
            if let context = ProcessManager.shared.processHelperContext() {
                let path:String = "/bin/zsh"
                let arguments = ["-c", "ioreg -l | grep Voltage | tr ',' '\\n' | sed 's/[{}]//g' | sed 's/\"//g'"]

                var charger:String?
                var voltage:Double?
                var manufacture:String?
                var accumulated:Double?
                var cycles:Int?
                var capacity:Double?
                var serial:String?
                var available:Double?

                context.helperProcessTaskWithArguments(.launch, path: path, arguments: arguments, whitespace: false) { response in
                    guard let response = response else {
                        return
                        
                    }
                    
                    for line in response.components(separatedBy: "\n") {
                        let components = line.components(separatedBy: "=")

                        if components.count == 2 {
                            switch components[0] {
                                case "Name" : charger = components[1]
                                case "AdapterVoltage" : voltage = Double(components[1])
                                case "Manufacturer" : manufacture = components[1]
                                case "AccumulatedWallEnergyEstimate" : accumulated = Double(components[1])
                                case "CycleCount" : cycles = Int(components[1])
                                case "DesignCapacity" : capacity = Double(components[1])
                                case "Capacity" : available = Double(components[1])
                                case "Serial" : serial = components[1]
                                default : break
                                
                            }
                            
                        }
                        
                    }
                

                    DispatchQueue.main.async {
                        self.info = .init(available: available, capacity: capacity, voltage: voltage, charger: charger, manufacturer:manufacture, accumulated:accumulated, serial: serial)
                        self.health = .init(available: available, capacity: capacity, cycles: cycles)
                        
                    }
                    
                }
            
            }
                    
        }
                
    #endif
    
    #if os(macOS)
        private func powerReadData(_ key:String, type:DataType?) -> Double? {
            do {
                try SMCKit.open()
            
                let int8 = SMCKit.getKey(key, type: DataTypes.UInt8)
                let int16 = SMCKit.getKey(key, type: DataTypes.UInt16)
                let int32 = SMCKit.getKey(key, type: DataTypes.UInt32)
                let sp78 = SMCKit.getKey(key, type: DataTypes.SP78)

                if let type = type {
                    if let value = try? SMCKit.readData(SMCKit.getKey(key, type: type)) {
                        return Double(UInt16(value.0) << 8 | UInt16(value.1))
                        
                    }
                    
                }
                
                if let value = try? SMCKit.readData(sp78) {
                    let output = value.0
                
                    return Double(output)
                    
                }
                else if let value = try? SMCKit.readData(int32) {
                    let output = UInt32(value.0) << 4 | UInt32(value.1)

                    return Double(output)
                    
                }
                else if let value = try? SMCKit.readData(int16) {
                    let output = UInt16(value.0) << 4 | UInt16(value.1)

                    return Double(output)

                }
                else if let value = try? SMCKit.readData(int8) {
                    let output = UInt8(value.0) << 4 | UInt8(value.1)
                    return Double(output)
                    
                }
                    
            }
            catch {
                print("Error opening SMC: \(error)")
                
            }
            
            return nil
            
        }
    
    #endif
    
    
}
