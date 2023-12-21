//
//  BatteryManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import Foundation
import Combine
import EnalogSwift
import CoreData

#if os(macOS)
    import IOKit.pwr_mgt
    import IOKit.ps
    import IOKit
    import AppKit

#elseif os(iOS)
    import UIKit

#endif

class BatteryManager:ObservableObject {
    static var shared = BatteryManager()

    @Published var charging:BatteryChargingState = .charging
    @Published var percentage:Int = 100
    @Published var remaining:BatteryRemaining? = nil
    @Published var mode:BatteryModeType = .unavailable
    @Published var max:Int = 100

    #if os(macOS)
        @Published var health:BatteryHealthObject? = nil
        @Published var thermal:BatteryThemalObject = .init(20)
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
        
        AppManager.shared.appTimer(1).dropFirst(2).sink { _ in
            self.powerStatus()
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
        
        $percentage.removeDuplicates().sink() { newValue in
            self.powerStoreEvent(nil)

        }.store(in: &updates)
        
        $charging.dropFirst().removeDuplicates().sink() { newValue in
            switch newValue {
                case .battery : self.powerStoreEvent(nil, force: .chargingStopped)
                case .charging : self.powerStoreEvent(nil, force: .chargingBegan)
                
            }

        }.store(in: &updates)
        
      
        
        $mode.dropFirst().removeDuplicates().sink() { newValue in
            self.powerStoreEvent(nil)
                
        }.store(in: &updates)
        
        #if os(macOS)
            $thermal.dropFirst().removeDuplicates().receive(on: DispatchQueue.global()).sink() { newValue in
                self.powerStoreEvent(nil, force: .deviceOverheating)

            }.store(in: &updates)

        #endif
        
        #if os(macOS)
            if #available(macOS 12.0, *) {
                NotificationCenter.default.addObserver(self, selector: #selector(self.powerStateNotification(notification:)), name:  NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil)
                
            }
        
        #else
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
        self.powerStatus()
        self.powerEfficiencyMode()
       
        #if os(macOS)
            self.powerTempratureCheck()
            self.powerMetrics()
        
        #endif
        
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
    
    #if os(macOS)
        public func powerChargeLimit(_ upper:Int) {
            if AppManager.shared.distribution == .direct {
                if let value = UInt8(exactly: upper), let context = ProcessManager.shared.processHelperContext() {
                    var limit:UInt8
                    switch value {
                        case let x where x < 50 :  limit = 50
                        case let x where x > 100 : limit = 100
                        default : limit = value
                        
                    }
                    
                    context.helperWriteData(key: "BCLM", value: limit) { state in
                        print("state" ,state)
                        
                    }
                    
                }
                
            }

        }
    
    #endif
    
    private func powerUpdaterFallback() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let counter = self.counter {
                if counter.isMultiple(of: 1) {
                    self.powerStatus()
                    
                }
                
                if counter.isMultiple(of: 6) {
                    //self.remaining = self.powerRemaing
                    
                }
                
            }
            
            self.counter = (self.counter ?? 0) + 1
            
        }
        
    }
    
    @objc private func powerStateNotification(notification: Notification?) {
        self.powerForceRefresh()
        
    }
    
    private func powerStatus() {
        #if os(macOS)
            DispatchQueue.main.async {
                if let battery = try? SMCKit.batteryInformation() {
                    switch battery.isCharging {
                        case true : self.charging = .charging
                        case false : self.charging =  .battery
                        
                    }
                    
                    self.info?.powered = battery.isACPresent
                    self.info?.batteries = battery.batteryCount
                    
                    if let max = self.powerReadData("BCLM", type: nil) {
                        self.max = Int(max)
                        
                    }
                    
                    guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
                        return
                        
                    }
                    
                    if let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as NSArray?  {
                        for ps in sources as NSArray {
                            let source: CFTypeRef = ps as CFTypeRef
                            let dict = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef).takeUnretainedValue() as NSDictionary
                            
                            if let type = dict[kIOPSTypeKey] as? String {
                                if type == kIOPSInternalBatteryType {
                                    self.percentage = dict[kIOPSCurrentCapacityKey] as? Int ?? 0
                                    
                                }

                            }
                            
                        }
                        
                    }
                    
                }
                
            }

        #elseif os(iOS)
            switch UIDevice.current.batteryState {
                case .charging : self.charging = .charging
                case .full : self.charging = .charging
                default : self.charging = .battery
                
            }
        
            self.percentage = Int(UIDevice.current.batteryLevel * 100)

        #endif
        
    }
    
    public func powerStoreEvent(_ device:SystemDeviceObject?, battery:Int? = nil, force:SystemAlertTypes? = nil) {
        if let context = AppManager.shared.appStorageContext() {
            var predicates = Array<NSPredicate>()
            predicates.append(NSPredicate(format: "session != %@", AppManager.shared.sessionid as CVarArg))
            
            guard let system = UserDefaults.main.object(forKey: SystemDefaultsKeys.deviceIdentifyer.rawValue) as? String else {
                return
                
            }
            
            if let device = device?.id {
                guard let battery = battery else {
                    return
                    
                }
                
                predicates.append(NSPredicate(format: "SELF.device.id == %@", device as CVarArg))
                predicates.append(NSPredicate(format: "percent == %d" ,Int16(battery)))
                predicates.append(NSPredicate(format: "created > %@", Date(timeIntervalSinceNow: -10 * 60 * 60) as NSDate))

            }
            else if let system = UUID(uuidString: system) {
                predicates.append(NSPredicate(format: "SELF.device.id == %@", system as CVarArg))
                predicates.append(NSPredicate(format: "percent == %d" ,Int16(self.percentage)))
                predicates.append(NSPredicate(format: "created > %@", Date(timeIntervalSinceNow: -2 * 60 * 60) as NSDate))

            }
               
            
            print("\n\npredicates" ,predicates)
            
            let fetch = Battery.fetchRequest() as NSFetchRequest<Battery>
            fetch.includesPendingChanges = true
            fetch.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
            fetch.fetchLimit = 1
            fetch.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]

            do {
                if let last = try context.fetch(fetch).first {
                    if let converted = SystemEventObject(last) {
                        AlertManager.shared.alertCreate(event: converted, force: force, context: context)
                        
                    }
                    
                }
                else {
                    let store = Battery(context: context) as Battery
                    store.id = UUID()
                    store.created = Date()
                    store.device = self.appDevice(device, context: context)
                    store.session = AppManager.shared.sessionid
                    
                    if device != nil {
                        guard let battery = battery else {
                            return
                            
                        }
                        
                        store.mode = BatteryModeType.normal.rawValue
                        store.state = BatteryChargingState.battery.rawValue
                        store.percent = Int16(battery)

                    }
                    else {
                        store.percent = Int16(self.percentage)
                        store.state = self.charging.rawValue
                        store.mode = self.mode.rawValue
                        
                        #if os(macOS)
                            store.temprature = Int16(self.thermal.value)

                            if let cycles = self.health?.cycles {
                                store.cycles = Int16(cycles)

                            }
                        
                        #endif
                        
                        if let version = Float(SystemDeviceTypes.os.replacingOccurrences(of: ".", with: "")) {
                            store.os = Int16(version)
                            
                        }

                        if let converted = SystemEventObject(store) {
                            AlertManager.shared.alertCreate(event: converted, force: force, context: context)
                            
                        }

                    }
                   
                    try context.save()
                    
                }
                
            }
            catch {
                
            }
            
        }

    }
    
    private func appDevice(_ device:SystemDeviceObject? ,context:NSManagedObjectContext) -> Devices? {
        if let match = SystemDeviceObject.match(device, context: context) {
            let fetch = Devices.fetchRequest() as NSFetchRequest<Devices>
            fetch.includesPendingChanges = true
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "id == %@", match.id as CVarArg)
            
            if let device = try? context.fetch(fetch).first {
                return device
                
            }
            
        }
        
        return nil
        
    }
    
    #if os(macOS)
        private func powerTempratureCheck() {
            if let value = self.powerReadData("TB0T", type: DataTypes.UInt16) {
                DispatchQueue.main.async {
                    self.thermal = .init(Double(value / 100))
                   
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
                var watts:Double?

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
                                case "Watts" : watts = Double(components[1])
                                case "CycleCount" : cycles = Int(components[1])
                                case "DesignCapacity" : capacity = Double(components[1])
                                case "Capacity" : available = Double(components[1])
                                case "Serial" : serial = components[1]
                                default : break
                                
                            }
                            
                        }
                        
                    }
                
                    DispatchQueue.main.async {
                        self.info = .init(available: available, capacity: capacity, voltage: voltage, charger: charger, manufacturer:manufacture, accumulated:accumulated, serial: serial, watts: watts)
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
