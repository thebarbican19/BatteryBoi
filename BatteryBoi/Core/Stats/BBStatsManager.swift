//
//  BBStatsManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/28/23.
//

import Foundation
import Combine
import CoreData
import CloudKit

public class StatsManager: ObservableObject {
    static var shared = StatsManager()

    @Published var title: String
    @Published var subtitle: String

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
//        var matches = [SystemEventObject]()
//        if let device = device {
//            matches = AppManager.shared.events.filter({ $0.device == device && $0.state == .depleted && $0.notify != .none })
//
//        }
//        else {
//            matches = AppManager.shared.events.filter({ $0.device?.system == true && $0.state == .depleted && $0.notify != .none })
//
//        }
        
//        if matches.isEmpty == false {
//            
//        }
        
    }
    
    public func statsAverageChargeTime(_ device:SystemDeviceObject?) {
//        if let device = device {
//            let matches = AppManager.shared.events.filter({ $0.device == device && $0.state == .charging && $0.notify != .none }).prefix(30)
//            
//        }
//        else {
//            
//        }

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
                    case .deviceDisconnected:return "AlertDeviceDisconnectedTitle".localise()
                    default : return device.name
                    
                }
                            
            }
            else {
                let percent = Int(BatteryManager.shared.percentage)
                let state = BatteryManager.shared.charging
                
                switch AppManager.shared.alert {
                    case .chargingComplete:return "AlertChargingCompleteTitle".localise()
                    case .chargingBegan:return "AlertChargingTitle".localise()
                    case .chargingStopped:return "AlertChargingStoppedTitle".localise()
                    case .deviceDepleting:return "AlertSomePercentTitle".localise([percent])
                    case .deviceConnected:return "AlertDeviceConnectedTitle".localise()
                    case .deviceDisconnected:return "AlertDeviceDisconnectedTitle".localise()
                    case .deviceOverheating:return "AlertOverheatingTitle".localise()
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
            let state = BatteryManager.shared.charging
            let percent = Int(BatteryManager.shared.percentage)
            let remaining = BatteryManager.shared.remaining

            switch AppManager.shared.alert {
                case .chargingComplete:return "AlertChargedSummary".localise()
                case .chargingBegan:return "AlertStartedChargeSummary".localise([ "AlertDeviceUnknownTitle".localise()])
                case .chargingStopped:return "AlertEstimateSummary".localise([remaining?.formatted ?? "AlertDeviceUnknownTitle".localise()])
                case .deviceDepleting:return "AlertPercentSummary".localise()
                case .deviceOverheating:return "AlertOverheatingSummary".localise()
                default : break
                
            }
            
            if state == .charging {
                switch percent {
                    case 100 : return "AlertChargedSummary".localise()
                    default : return "AlertStartedChargeSummary".localise(["AlertDeviceUnknownTitle".localise()])
                    
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
                    default : return .init(name: "ChargingIcon", system: false)

                }
                
//            }
                    
        }

    #endif
    
}
