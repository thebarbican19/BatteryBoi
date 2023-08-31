//
//  BBStatsManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/28/23.
//

import Foundation
import EnalogSwift
import Combine

class StatsManager:ObservableObject {
    static var shared = StatsManager()
    
    @Published var display:String?
    @Published var title:String
    @Published var subtitle:String

    private var updates = Set<AnyCancellable>()

    init() {
        self.display = ""
        self.title = ""
        self.subtitle = ""
        
        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            if key == .enabledDisplay {
                self.display = self.statsDisplay
                
            }
                       
        }.store(in: &updates)
        
        AppManager.shared.$alert.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
        }.store(in: &updates)
        
        BatteryManager.shared.$charging.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
        }.store(in: &updates)

        BatteryManager.shared.$percentage.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
        }.store(in: &updates)

        BatteryManager.shared.$saver.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
        }.store(in: &updates)
        
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
    private var statsDisplay:String? {
        let display = SettingsManager.shared.enabledDisplay(false)
        let state = BatteryManager.shared.charging.state
        
        if state == .charging {
            if display == .empty {
                return nil
                
            }
            
        }
        else {
            if SettingsManager.shared.enabledDisplay() == .countdown {
                if let remaining = BatteryManager.shared.remaining, let hour = remaining.hours, let minute = remaining.minutes {
                    if hour > 0 && minute > 0 {
                       return "+\(hour)\("TimestampHourAbbriviatedLabel".localise())"

                    }
                    else if hour > 0 && minute == 0 {
                        return "\(hour)\("TimestampHourAbbriviatedLabel".localise())"

                    }
                    else if hour == 0 && minute > 0 {
                        return "\(minute)\("TimestampMinuteAbbriviatedLabel".localise())"

                    }
                        
                }
                
            }
            
        }
        
        return "\(Int(BatteryManager.shared.percentage))"

    }
    
    private var statsTitle:String {
        let percent = Int(BatteryManager.shared.percentage)
        let state = BatteryManager.shared.charging.state
        let device = AppManager.shared.device?.device ?? "AlertDeviceUnknownTitle".localise()
        
        switch AppManager.shared.alert {
            case .chargingComplete:return "AlertChargingCompleteTitle".localise()
            case .chargingBegan:return "AlertChargingTitle".localise()
            case .chargingStopped:return "AlertChargingStoppedTitle".localise()
            case .percentFive:return "AlertSomePercentTitle".localise([percent])
            case .percentTen:return "AlertSomePercentTitle".localise([percent])
            case .percentTwentyFive:return "AlertSomePercentTitle".localise([percent])
            case .percentOne:return "AlertOnePercentTitle".localise()
            case .deviceConnected:return "AlertDeviceConnectedTitle".localise([device])
            case .deviceRemoved:return "AlertDeviceDisconnectedTitle".localise([device])
            default : break
            
        }
        
        if state == .battery {
            return "AlertSomePercentTitle".localise([percent])

        }
        
        return "AlertChargingTitle".localise()

    }
    
    private var statsSubtitle:String {
        let state = BatteryManager.shared.charging.state
        let percent = Int(BatteryManager.shared.percentage)
        let remaining = BatteryManager.shared.remaining
        let full = BatteryManager.shared.powerUntilFull

        switch AppManager.shared.alert {
            case .chargingComplete:return "AlertChargedSummary".localise()
            case .chargingBegan:return "AlertStartedChargeSummary".localise([full?.time ?? "AlertDeviceUnknownTitle".localise()])
            case .chargingStopped:return "AlertEstimateSummary".localise([remaining?.formatted ?? "AlertDeviceUnknownTitle".localise()])
            case .percentFive:return "AlertPercentSummary".localise()
            case .percentTen:return "AlertPercentSummary".localise()
            case .percentTwentyFive:return "AlertPercentSummary".localise()
            case .percentOne:return "AlertPercentSummary".localise()
            case .deviceConnected:return "TBA".localise([percent])
            case .deviceRemoved:return "TBA".localise([percent])
            default : break

        }
        
        if state == .charging {
            switch percent {
                case 100 : return "AlertChargedSummary".localise()
                default : return "AlertStartedChargeSummary".localise([full?.time ?? "AlertDeviceUnknownTitle".localise()])
                
            }

        }
        
        return "AlertEstimateSummary".localise([remaining?.formatted ?? "AlertDeviceUnknownTitle".localise()])

    }
    
}
