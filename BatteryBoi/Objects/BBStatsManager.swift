//
//  BBStatsManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/28/23.
//

import Foundation
import EnalogSwift
import Combine
import CoreData
import CloudKit

class StatsManager:ObservableObject {
    static var shared = StatsManager()
    
    @Published var title:String
    @Published var subtitle:String

    private var updates = Set<AnyCancellable>()
    
    init() {
        self.title = ""
        self.subtitle = ""
        
        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            #if os(macOS)
                
            
            #endif
                           
        }.store(in: &updates)
        
        BatteryManager.shared.$percentage.removeDuplicates().receive(on: DispatchQueue.main).sink() { newValue in
            #if os(macOS)
               self.title = self.statsTitle
               self.subtitle = self.statsSubtitle
           
            #endif

       }.store(in: &updates)
            
        BatteryManager.shared.$charging.removeDuplicates().receive(on: DispatchQueue.main).sink() { newValue in
            #if os(macOS)
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
        
            #endif
        
        }.store(in: &updates)

        #if os(macOS)
            AppManager.shared.$alert.receive(on: DispatchQueue.main).sink() { newValue in
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
                
            }.store(in: &updates)

        #endif

        #if os(macOS)
            BatteryManager.shared.$thermal.receive(on: DispatchQueue.main).sink() { newValue in
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
                
            }.store(in: &updates)
        
        #endif

        #if os(macOS)
            AppManager.shared.$selected.receive(on: DispatchQueue.main).sink() { newValue in
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
                
            }.store(in: &updates)
        
        #endif
        
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
    }
    
    public func statsAverageChargePerVersion() {
        
    }
    
    public func statsAverageDepletionTime(_ device:SystemDeviceObject?) {
        
    }
    
    public func statsAverageChargeTime(_ device:SystemDeviceObject?) {
        
    }
    
    public func statsSystemDevicesTypes() {
        
    }
    
    private var statsCountdown:String? {
        #if os(macOS)
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
        
        #endif
        
        return nil
        
    }
        
    #if os(macOS)
        private var statsTitle:String {
            if let device = AppManager.shared.selected {
                switch AppManager.shared.alert {
                    case .deviceConnected:return "AlertDeviceConnectedTitle".localise()
                    case .deviceRemoved:return "AlertDeviceDisconnectedTitle".localise()
                    default : return device.name
                    
                }
                            
            }
            else {
                let percent = Int(BatteryManager.shared.percentage)
                let state = BatteryManager.shared.charging.state
                
                switch AppManager.shared.alert {
                    case .chargingComplete:return "AlertChargingCompleteTitle".localise()
                    case .chargingBegan:return "AlertChargingTitle".localise()
                    case .chargingStopped:return "AlertChargingStoppedTitle".localise()
                    case .percentFive:return "AlertSomePercentTitle".localise([percent])
                    case .percentTen:return "AlertSomePercentTitle".localise([percent])
                    case .percentTwentyFive:return "AlertSomePercentTitle".localise([percent])
                    case .percentOne:return "AlertOnePercentTitle".localise()
                    case .deviceConnected:return "AlertDeviceConnectedTitle".localise()
                    case .deviceRemoved:return "AlertDeviceDisconnectedTitle".localise()
                    case .deviceOverheating:return "AlertOverheatingTitle".localise()
                    case .userEvent:return "AlertLimitedTitle".localise()
                    default : break
                    
                }
                
                if state == .battery {
                    return "AlertSomePercentTitle".localise([percent])
                    
                }
             
                return "AlertChargingTitle".localise()

            }

        }
    
    #endif

    #if os(macOS)
    private var statsSubtitle:String {
        if let device = AppManager.shared.selected {
//            switch AppManager.shared.alert {
//                case .deviceConnected:return device.device ?? device.type.type.name
//                case .deviceRemoved:return device.device ?? device.type.type.name
//                default : break
//                
//            }
//            
//            if let battery = device.battery.percent {
//                return "AlertSomePercentTitle".localise([Int(battery)])
//
//            }
                
            return "BluetoothInvalidLabel".localise()
            
        }
        else {
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
    //                case .userEvent:return "AlertLimitedSummary".localise([event?.name ?? "Unknown Event"])
                case .deviceOverheating:return "AlertOverheatingSummary".localise()
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
    #endif

    #if os(macOS)
        public var statsIcon:StatsIcon {
//            if let device = AppManager.shared.device {
//                return .init(name: device.type.icon, system: true)
//                
//            }
//            else {
                switch AppManager.shared.alert {
                    case .deviceOverheating : return .init(name: "OverheatIcon", system: false)
                    case .userEvent : return .init(name: "EventIcon", system: false)
                    default : return .init(name: "ChargingIcon", system: false)

                }
                
//            }
                    
        }

    #endif
    
}
