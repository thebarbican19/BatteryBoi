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

struct StatsContainerObject {
    var container:NSPersistentCloudKitContainer?
    var directory:URL?
    var parent:URL?

}


class StatsManager:ObservableObject {
    static var shared = StatsManager()
    
    @Published var display:String?
    @Published var overlay:String?
    @Published var title:String
    @Published var subtitle:String

    private var updates = Set<AnyCancellable>()

    static var container: StatsContainerObject = {
        let object = "BBDataObject"
        let container = NSPersistentCloudKitContainer(name: object)
        
        var directory: URL?
        var subdirectory: URL?

        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last {
            let parent = support.appendingPathComponent("BatteryBoi")
                        
            do {
                try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)
                
                let file = parent.appendingPathComponent("\(object).sqlite")
                directory = file
                container.persistentStoreDescriptions = [
                    NSPersistentStoreDescription(url: file)
                ]
                
                subdirectory = parent
            }
            catch {
                print("Error creating or setting SQLite store URL: \(error)")
                
            }
            
        } 
        else {
            print("Error retrieving Application Support directory URL.")
            
        }

        if let description = container.persistentStoreDescriptions.first {
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
        }
        else {
            print("Error: No persistent store description found.")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                print("Error loading persistent stores: \(error)")
                
            }
            
            if let path = directory {
                directory = storeDescription.url
                print("directory" ,directory ?? "")
                
            }
            
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return .init(container: container, directory: directory, parent: subdirectory)
        
    }()

    init() {
        self.display = nil
        self.title = ""
        self.subtitle = ""
        
        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            if key == .enabledDisplay {
                self.display = self.statsDisplay
                self.overlay = self.statsOverlay

            }
                       
        }.store(in: &updates)
        
        AppManager.shared.$alert.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.overlay = self.statsOverlay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
        }.store(in: &updates)
        
        BatteryManager.shared.$charging.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.overlay = self.statsOverlay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
            DispatchQueue.global(qos: .background).async {
                switch newValue.state {
                    case .battery : self.statsStore(.disconnected, device: nil)
                    case .charging : self.statsStore(.connected, device: nil)
                    
                }
                
            }
            
        }.store(in: &updates)

        BatteryManager.shared.$percentage.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.overlay = self.statsOverlay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
            DispatchQueue.global(qos: .background).async {
                switch BatteryManager.shared.charging.state {
                    case .battery : self.statsStore(.depleted, device: nil)
                    case .charging : self.statsStore(.charging, device: nil)
                    
                }
                
            }
            
        }.store(in: &updates)

        BatteryManager.shared.$saver.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.overlay = self.statsOverlay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
        }.store(in: &updates)

        BatteryManager.shared.$thermal.receive(on: DispatchQueue.main).sink() { newValue in
            self.display = self.statsDisplay
            self.overlay = self.statsOverlay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
        }.store(in: &updates)
        
        BluetoothManager.shared.$connected.removeDuplicates().receive(on: DispatchQueue.main).sink() { newValue in
            self.overlay = self.statsOverlay
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
            if let device = newValue.first(where: { $0.updated.now == true }) {
                DispatchQueue.global().async {
                    self.statsStore(.depleted, device: device)

                }

            }
            
        }.store(in: &updates)
        
        AppManager.shared.$device.receive(on: DispatchQueue.main).sink() { newValue in
            self.title = self.statsTitle
            self.subtitle = self.statsSubtitle
            
        }.store(in: &updates)
        
        AppManager.shared.appTimer(3600).sink { _ in
            DispatchQueue.global().async {
                self.statsWattageStore()
                
            }
            
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
    
    private var statsCountdown:String? {
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
        
        return nil
        
    }
    
    private var statsTitle:String {
        if let device = AppManager.shared.device {
            switch AppManager.shared.alert {
                case .deviceConnected:return "AlertDeviceConnectedTitle".localise()
                case .deviceRemoved:return "AlertDeviceDisconnectedTitle".localise()
                default : return device.device ?? device.type.type.name
                
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
    
    private var statsSubtitle:String {
        if let device = AppManager.shared.device {
            switch AppManager.shared.alert {
                case .deviceConnected:return device.device ?? device.type.type.name
                case .deviceRemoved:return device.device ?? device.type.type.name
                default : break
                
            }
            
            if let battery = device.battery.percent {
                return "AlertSomePercentTitle".localise([Int(battery)])

            }
                
            return "BluetoothInvalidLabel".localise()
            
        }
        else {
            let state = BatteryManager.shared.charging.state
            let percent = Int(BatteryManager.shared.percentage)
            let remaining = BatteryManager.shared.remaining
            let full = BatteryManager.shared.powerUntilFull
            let event = EventManager.shared.events.sorted(by: { $0.start > $1.start }).first

            switch AppManager.shared.alert {
                case .chargingComplete:return "AlertChargedSummary".localise()
                case .chargingBegan:return "AlertStartedChargeSummary".localise([full?.time ?? "AlertDeviceUnknownTitle".localise()])
                case .chargingStopped:return "AlertEstimateSummary".localise([remaining?.formatted ?? "AlertDeviceUnknownTitle".localise()])
                case .percentFive:return "AlertPercentSummary".localise()
                case .percentTen:return "AlertPercentSummary".localise()
                case .percentTwentyFive:return "AlertPercentSummary".localise()
                case .percentOne:return "AlertPercentSummary".localise()
                case .userEvent:return "AlertLimitedSummary".localise([event?.name ?? "Unknown Event"])
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
    
    public var statsIcon:StatsIcon {
        if let device = AppManager.shared.device {
            return .init(name: device.type.icon, system: true)
            
        }
        else {
            switch AppManager.shared.alert {
                case .deviceOverheating : return .init(name: "OverheatIcon", system: false)
                case .userEvent : return .init(name: "EventIcon", system: false)
                default : return .init(name: "ChargingIcon", system: false)

            }
            
        }
                
    }
    
    private func statsContext() -> NSManagedObjectContext? {
        if let container = StatsManager.container.container {
            let context = container.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            return context
            
        }
        
        return nil
        
    }
    
    private func statsStore(_ state:StatsStateType, device:BluetoothObject?) {
        if let context = self.statsContext() {
            context.performAndWait {
                let expiry = Date().addingTimeInterval(-2 * 60)
                var charge:Int64 = 100
                if let percent = device {
                    charge = Int64(percent.battery.percent ?? 100)
                    
                }
                else {
                    charge = Int64(BatteryManager.shared.percentage)
                    
                }
                
                let fetch = Activity.fetchRequest() as NSFetchRequest<Activity>
                fetch.includesPendingChanges = true
                fetch.predicate = NSPredicate(format: "state == %@ && device == %@ && charge == %d &&  timestamp > %@" ,state.rawValue, device?.address ?? "" ,charge ,expiry as NSDate)
                
                do {
                    if try context.fetch(fetch).first == nil {
                        let store = Activity(context: context) as Activity
                        store.timestamp = Date()
                        store.device = device?.address ?? ""
                        store.state = state.rawValue
                        store.charge = charge
                        
                        try context.save()
                        
                    }
                    
                }
                catch {
                    print("Error" ,error)
                    
                }
                
            }
            
        }
        
    }
    
    private func statsWattageStore() {
        if let context = self.statsContext() {
            context.performAndWait {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day, .hour], from: Date())

                if let hour = calendar.date(from: components) {
                    let fetch = Wattage.fetchRequest() as NSFetchRequest<Wattage>
                    fetch.includesPendingChanges = true
                    fetch.predicate = NSPredicate(format: "timestamp == %@" ,hour as CVarArg)
                    
                    do {
                        if try context.fetch(fetch).first == nil {
                            let store = Wattage(context: context) as Wattage
                            store.timestamp = Date()
                            store.device = AppManager.shared.appDeviceType.name
                            store.wattage = BatteryManager.shared.powerHourWattage() ?? 0.0
                            
                            try context.save()
                            
                        }
                        
                    }
                    catch {
                        
                    }
                    
                }
                    
            }
            
        }
        
    }
    
}
