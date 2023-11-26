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

enum StatsActivityNotificationType:String {
    case alert
    case background
    case none
    
}

struct StatsIcon {
    var name:String
    var system:Bool
    
}

enum StatsStateType:String {
    case charging
    case depleted
    case connected
    case disconnected
    
}

struct StatsDisplayObject {
    var standard:String?
    var overlay:String?
    
}

class StatsManager:ObservableObject {
    static var shared = StatsManager()
    
    @Published var display:String?
    @Published var overlay:String?
    @Published var title:String
    @Published var subtitle:String

    private var updates = Set<AnyCancellable>()
    
    init() {
        self.display = nil
        self.title = ""
        self.subtitle = ""
        
        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            #if os(macOS)
                if key == .enabledDisplay {
                    self.display = self.statsDisplay
                    self.overlay = self.statsOverlay

                }
            
            #endif
                           
        }.store(in: &updates)
        
        BatteryManager.shared.$percentage.removeDuplicates().receive(on: DispatchQueue.main).sink() { newValue in
            #if os(macOS)
               self.display = self.statsDisplay
               self.overlay = self.statsOverlay
               self.title = self.statsTitle
               self.subtitle = self.statsSubtitle
           
            #endif
           
            DispatchQueue.global(qos: .background).async {
                switch BatteryManager.shared.charging.state {
                    case .battery : AppManager.shared.appStoreEvent(.disconnected, device: nil, notification: .background)
                    case .charging : AppManager.shared.appStoreEvent(.connected, device: nil, notification: .background)

                }

            }

       }.store(in: &updates)
            
        BatteryManager.shared.$charging.removeDuplicates().receive(on: DispatchQueue.main).sink() { newValue in
            #if os(macOS)
                self.display = self.statsDisplay
                self.overlay = self.statsOverlay
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
        
            #endif
            
            DispatchQueue.global(qos: .background).async {
                switch newValue.state {
                    case .battery : AppManager.shared.appStoreEvent(.disconnected, device: nil, notification: .background)
                    case .charging : AppManager.shared.appStoreEvent(.connected, device: nil, notification: .background)

                }

            }


        }.store(in: &updates)

        #if os(macOS)
            AppManager.shared.$alert.receive(on: DispatchQueue.main).sink() { newValue in
                self.display = self.statsDisplay
                self.overlay = self.statsOverlay
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
                
            }.store(in: &updates)

        #endif
        
        #if os(macOS)
            BatteryManager.shared.$saver.receive(on: DispatchQueue.main).sink() { newValue in
                self.display = self.statsDisplay
                self.overlay = self.statsOverlay
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
                
            }.store(in: &updates)
        
        #endif

        #if os(macOS)
            BatteryManager.shared.$thermal.receive(on: DispatchQueue.main).sink() { newValue in
                self.display = self.statsDisplay
                self.overlay = self.statsOverlay
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
                
            }.store(in: &updates)
        
        #endif

//        BluetoothManager.shared.$connected.removeDuplicates().receive(on: DispatchQueue.main).sink() { newValue in
//            self.overlay = self.statsOverlay
//            self.title = self.statsTitle
//            self.subtitle = self.statsSubtitle
//            
//            if let device = newValue.first(where: { $0.updated.now == true }) {
//                DispatchQueue.global().async {
//                    self.statsStoreDevice(device)
//                    self.statsStoreEvent(.depleted, device: device, notification: .background)
//
//                }
//
//            }
//            
//        }.store(in: &updates)
        
        #if os(macOS)
            AppManager.shared.$device.receive(on: DispatchQueue.main).sink() { newValue in
                self.title = self.statsTitle
                self.subtitle = self.statsSubtitle
                
            }.store(in: &updates)
        
        #endif

        #if os(macOS)
            AppManager.shared.appTimer(3600).sink { _ in
                DispatchQueue.global().async {
                    AppManager.shared.appWattageStore()
                    
                }
                
            }.store(in: &updates)
        
        #endif
        
    }
    
    deinit {
        self.updates.forEach { $0.cancel() }
        
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
        private var statsDisplay:String? {
            let display = SettingsManager.shared.enabledDisplay(false)
            let state = BatteryManager.shared.charging.state
            
            if state == .charging {
                if display == .empty {
                    return nil
                    
                }
                
            }
            else {
                if display == .empty {
                    return nil
                    
                }
                else if SettingsManager.shared.enabledDisplay() == .countdown {
                    return self.statsCountdown
                    
                }
                else if SettingsManager.shared.enabledDisplay() == .cycle {
                    if let cycle = BatteryManager.shared.metrics?.cycles.formatted {
                        return cycle

                    }

                }
                
            }
            
            return "\(Int(BatteryManager.shared.percentage))"

        }

    #endif

    #if os(macOS)
        private var statsOverlay:String? {
            let state = BatteryManager.shared.charging.state

            if state == .charging {
                return nil
                
            }
            else {
                if SettingsManager.shared.enabledDisplay() == .countdown {
                    return "\(Int(BatteryManager.shared.percentage))"
                    
                }
                else if SettingsManager.shared.enabledDisplay() == .empty {
                    return "\(Int(BatteryManager.shared.percentage))"

                }
                else {
                    return self.statsCountdown
                    
                }
                
            }
            
        }

    #endif
        
    #if os(macOS)
        private var statsTitle:String {
            if let device = AppManager.shared.device {
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
        if let device = AppManager.shared.device {
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
