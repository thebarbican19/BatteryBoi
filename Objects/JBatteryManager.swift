//
//  BatteryManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import Foundation
import Combine
import IOKit.ps

struct BatteryRemaining:Equatable {
    static func == (lhs: BatteryRemaining, rhs: BatteryRemaining) -> Bool {
        return lhs.date == rhs.date
        
    }
    
    var date:Date
    var hours:Int? = nil
    var minutes:Int? = nil
    
    init(hour: Int, minute:Int) {
        self.hours = hour
        self.minutes = minute
        self.date = Date(timeIntervalSinceNow: 60*2)

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        if let date = Calendar.current.date(byAdding: components, to: Date()) {
            self.date = date
            
        }
        
    }
    
}

class BatteryManager:ObservableObject {
    static var shared = BatteryManager()
    
    @Published var charging:Bool = false
    @Published var percentage:Float = 100
    @Published var remaining:BatteryRemaining? = nil
    @Published var formatted:String = ""

    private var updates = Set<AnyCancellable>()

    init() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.powerStatus(true)
                        
        }
        
        AppManager.shared.$estimate.removeDuplicates().sink() { newValue in
            self.formatted = ""
            self.powerStatus(true)

        }.store(in: &updates)
        
        $percentage.removeDuplicates().sink() { newValue in
            self.powerStatus()

        }.store(in: &updates)
        
        self.powerStatus(true)

    }
    
    private func powerStatus(_ force:Bool = false) {
        if force {
            self.percentage = self.powerPercentage

            switch self.powerCharging {
                case true : self.charging = true
                case false : self.charging = false

            }
        
        }
                        
        if SettingsManager.shared.enabledEstimateStatus == .restricted && self.powerRemaing != nil {
            SettingsManager.shared.enabledEstimateStatus = .enabled
            
        }

        if let remaining = self.powerRemaing, let hour = remaining.hours, let minute = remaining.minutes {
            if SettingsManager.shared.enabledEstimateStatus == .enabled && self.charging == false {
                if hour > 0 && minute > 0 {
                    //self.formatted = "\(hour)h \(minute)m"
                    self.formatted = "\(hour)h"

                }
                else if hour > 0 && minute == 0 {
                    self.formatted = "\(hour)h"

                }
                else if hour == 0 && minute > 0 {
                    self.formatted = "\(minute)m"

                }
                
                self.remaining = remaining
                
            }
            
        }
        
        if self.formatted.isEmpty == true {
            self.formatted = "\(Int(self.percentage))"

        }
   
    }
    
    private var powerCharging:Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let source = IOPSGetProvidingPowerSourceType(snapshot).takeRetainedValue()
        
        return source as String == kIOPSACPowerValue
        
    }

    private var powerPercentage:Float {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                
                if description["Type"] as? String == kIOPSInternalBatteryType {
                    return description[kIOPSCurrentCapacityKey] as? Float ?? 0.0
                    
                }
                
            }
            
        }
        
        return 100.0
        
    }
    
    private var powerRemaing:BatteryRemaining? {
        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", "pmset -g batt | grep -o '[0-9]\\{1,2\\}:[0-9]\\{2\\}'"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ":") {
            if let hour = output.map({ Int($0)}).first, let min = output.map({ Int($0)}).last {
                return .init(hour: hour ?? 0, minute: min ?? 0)
                
            }

        }
        
        return nil
        
    }
    
}
