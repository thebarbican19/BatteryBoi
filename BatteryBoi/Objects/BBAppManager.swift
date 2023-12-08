//
//  BBAppManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/9/23.
//

import Foundation
import EnalogSwift
import Combine
import SwiftUI
import CoreData
import CloudKit
import CoreBluetooth

#if os(iOS)
    import Deviice
#endif

class AppManager:ObservableObject {
    static var shared = AppManager()
    
    @Published var counter = 0
    @Published var list = Array<SystemDeviceObject>()
    @Published var selected:SystemDeviceObject? = nil
    @Published var updated:Date? = nil
        
    #if os(macOS)
        @Published var menu:SystemMenuView = .devices
        @Published var alert:SystemAlertTypes? = nil
    
    #endif

    private var updates = Set<AnyCancellable>()
    private var timer: AnyCancellable?

    init() {
        self.timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            
            guard let self = self else {
                return
                
            }
            
            if self.counter > 999 {
                self.appUsageTracker()
                
            }
                        
            self.counter += 1
            
        }
                
        self.timer?.store(in: &updates)
        
        $updated.receive(on: DispatchQueue.global()).debounce(for: .seconds(5), scheduler: RunLoop.main).sink { _ in
            self.appListDevices()

        }.store(in: &updates)
        
        $list.removeDuplicates().receive(on: DispatchQueue.global()).sink { items in
            for item in items  {
                print("List Devices \(item.name) - \(item.synced)")

            }
            
            for item in items.filter({ $0.synced == false }) {
                self.appStoreDevice(item)
               
            }
            
            self.appListDevices()

        }.store(in: &updates)

        CloudManager.shared.$syncing.removeDuplicates().receive(on: DispatchQueue.main).sink { state in
            if state == .completed {
                self.appStoreDevice()
                
            }
            
        }.store(in: &updates)
            
    }
    
    deinit {
        self.timer?.cancel()
        self.updates.forEach { $0.cancel() }
 
    }
    
    public func appUpdateList(_ device:SystemDeviceObject) {
        if self.list.contains(device) == false {
            self.list.append(device)
            
        }
        
    }
        
    public func appStoreEvent(_ state:StatsStateType, peripheral:CBPeripheral?, battery:Int? = nil) {
        if let context = self.appStorageContext() {
            context.performAndWait {
                var notify:StatsActivityNotificationType = .background
                
                let os = ProcessInfo.processInfo.operatingSystemVersion
                let version = Float("\(os.majorVersion).\(os.minorVersion)")
                
                if let last = self.appLatestEvent(state, device: peripheral, context: context) {
                    if let battery = battery {
                        switch battery {
                            case 25 : notify = .alert
                            case 15 : notify = .alert
                            case 10 : notify = .alert
                            case 5 : notify = .alert
                            case 1 : notify = .alert
                            default :notify = .none

                        }
                        
                        if battery != last.charge {
                            notify = .background
                            
                        }

                    }
                    
                    if let last = StatsStateType(rawValue: last.state ?? "") {
                        if last != state {
                            notify = .alert
                            
                        }
                        
                    }
                    
                }
                
                if let peripheral = peripheral {
                    if let device = self.appDevice(peripheral, context: context), let battery = battery {
                        
                        do {
                            let store = Events(context: context) as Events
                            store.id = UUID()
                            store.timestamp = Date()
                            store.state = state.rawValue
                            store.charge = Int64(battery)
                            store.device = device
                            store.reporter = self.appDevice(peripheral, context: context)
                            store.mode = BatteryModeType.normal.rawValue
                            store.notify = notify.rawValue
                            store.version = version ?? 0.0

                            try context.save()
                            
                        }
                        catch {
                            print("Error" ,error)
                            
                        }
                        
                    }
                    
                }
                else {
                    if let device = self.appDevice(nil, context: context) {
                        do {
                            let store = Events(context: context) as Events
                            store.id = UUID()
                            store.timestamp = Date()
                            store.state = state.rawValue
                            store.charge = Int64(BatteryManager.shared.percentage)
                            store.device = device
                            store.reporter = device
                            store.mode = BatteryManager.shared.saver.rawValue
                            store.version = version ?? 0.0
                            store.notify = notify.rawValue
                            
                            try context.save()
                            
                        }
                        catch {
                            print("Error" ,error)
                            
                        }
                        
                    }
                    
                }
    
            }
            
        }
        
    }
      
    public func appTimer(_ multiple: Int) -> AnyPublisher<Int, Never> {
        self.$counter.filter { $0 % multiple == 0 }.eraseToAnyPublisher()
        
    }
    
    public var appInstalled:Date {
        if let date = UserDefaults.main.object(forKey: SystemDefaultsKeys.versionInstalled.rawValue) as? Date {
            return date
            
        }
        else {
            UserDefaults.save(.versionInstalled, value: Date())
            
            EnalogManager.main.ingest(SystemEvents.userInstalled, description: "Installed App")
  
            return Date()
            
        }
        
    }
    
    public func appUsageTracker() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        if let latest = self.appUsage {
            let last = calendar.dateComponents([.year, .month, .day], from: latest.timestamp)
            let current = calendar.dateComponents([.year, .month, .day], from: Date())

            if let lastDate = calendar.date(from: last), let currentDate = calendar.date(from: current) {
                if currentDate > lastDate {
                    self.appUsage = .init(day: latest.day + 1, timestamp: Date())

                }
                
            }
            
        }
        else {
            self.appUsage = .init(day: 1, timestamp: Date())

        }
        
    }

    public var appUsage:SystemAppUsage? {
        get {
            let days = UserDefaults.main.object(forKey: SystemDefaultsKeys.usageDay.rawValue) as? Int
            let timestamp = UserDefaults.main.object(forKey: SystemDefaultsKeys.usageTimestamp.rawValue) as? Date
   
            if let days = days, let timestamp = timestamp {
                return .init(day: days, timestamp: timestamp)

            }
            
            return nil

        }
        
        set {
            if let newValue = newValue {
                UserDefaults.save(.usageDay, value: newValue.day)
                UserDefaults.save(.usageTimestamp, value: newValue.timestamp)

                EnalogManager.main.ingest(SystemEvents.userActive, description: "\(newValue.day) Days Active")
                
            }
            
        }
        
    }
    
    public var appIdentifyer:String {
        if let id = UserDefaults.main.object(forKey: SystemDefaultsKeys.versionIdenfiyer.rawValue) as? String {
            return id
            
        }
        else {
            var id = "US-\(UUID().uuidString)"
            #if os(macOS)
                id = "\(Locale.current.regionCode?.uppercased() ?? "US")-\(UUID().uuidString)"
            
            #elseif os(iOS)
                id = "\(Locale.current.region?.identifier.uppercased() ?? "US")-\(UUID().uuidString)"

            #endif
            
            UserDefaults.save(.versionIdenfiyer, value: id)

            return id
            
        }
        
    }
        
    private func appListDevices() {
        if let context = self.appStorageContext() {
            let fetch: NSFetchRequest<Devices> = Devices.fetchRequest()
//            fetch.predicate = NSPredicate(format: "name != %@", "")
            
            do {
                let list = try context.fetch(fetch)
                let mapped:[SystemDeviceObject] = list.compactMap({ .init($0) })

                DispatchQueue.main.async {
                    self.list = mapped
                    
                }

                print("trained" ,mapped)
                
            }
            catch {
                print("Error fetching Trained records: \(error)")
                
            }
            
        }
        
    }

    private func appLatestEvent(_ state:StatsStateType, device:CBPeripheral?, context:NSManagedObjectContext) -> Events? {
        var predicates = Array<NSPredicate>()
        
        if let name = device?.name {
            predicates.append(NSPredicate(format: "SELF.device.name == %@", name))
            predicates.append(NSPredicate(format: "state == %@", state.rawValue))

        }
        else if let id = UUID.device() {
            predicates.append(NSPredicate(format: "SELF.device.id == %@", id as CVarArg))
            predicates.append(NSPredicate(format: "state == %@", state.rawValue))

        }
        
        let fetch = Events.fetchRequest() as NSFetchRequest<Events>
        fetch.includesPendingChanges = true
        fetch.fetchLimit = 1
        fetch.predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)

        if predicates.isEmpty == false {
            if let existing = try? context.fetch(fetch).first {
                return existing
                
            }
                    
        }
        
        return nil
                
    }
    
    private func appStoreDevice(_ device:SystemDeviceObject? = nil) {
        if let context = self.appStorageContext() {
            context.performAndWait {
                let type = AppManager.shared.appDeviceType

                var predicates = Array<NSPredicate>()
                var name:String? = device?.name
                                
                if let device = device {
                    predicates.append(NSPredicate(format: "name == %@", device.name))
                    
                }
                else {
                    name = type.name(true)

                    if let match = self.appDeviceMatch() {
                        predicates.append(NSPredicate(format: "match == %@", match))
                        
                    }
                    
                    if let name = name {
                        predicates.append(NSPredicate(format: "name == %@", name))
                        
                    }

                }
                
                if predicates.isEmpty == false {
                    let fetch = Devices.fetchRequest() as NSFetchRequest<Devices>
                    fetch.includesPendingChanges = true
                    fetch.predicate = NSCompoundPredicate(type: .or, subpredicates: predicates)
                    fetch.fetchLimit = 1
                    
                    do {
                        var store:Devices?
                        if let existing = try context.fetch(fetch).first {
                            store = existing
                            store?.refreshed_on = Date()
                            
                            if let notifications = device?.notifications {
                                store?.notifications = notifications
                                
                            }
                            
                            if let favourite = device?.favourite {
                                store?.favourite = favourite
                                
                            }
                            
                            
                        }
                        else {
                            store = Devices(context: context) as Devices
                            store?.added_on = Date()
                            store?.refreshed_on = Date()
                            store?.notifications = true
                            
                            if let device = device {
                                store?.address = device.address
                                store?.id = device.id
                                store?.name = name
                                store?.vendor = device.profile?.hardware
                                store?.type = "TBA"
                                store?.primary = false
                                
                            }
                            else {
                                store?.name = name
                                store?.id = self.appDeviceMatch()
                                store?.subtype = type.name(false)
                                store?.type = type.category.rawValue
                                store?.primary = true
                                store?.vendor = "Apple Inc"
                                store?.product = type.name(false)
                                store?.serial = nil
                                store?.address = nil
                                
                                #if os(iOS)
                                    store?.os = UIDevice.current.systemVersion
                                
                                #endif

                            }
                            
                        }
                                                
                        try context.save()
                        
                    }
                    catch {
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    private func appDevice(_ device:CBPeripheral? ,context:NSManagedObjectContext) -> Devices? {
        let fetch = Devices.fetchRequest() as NSFetchRequest<Devices>
        fetch.includesPendingChanges = true
        fetch.fetchLimit = 1
        
        if device != nil {
            if let name = device?.name {
                fetch.predicate = NSPredicate(format: "name == %@", name)
                
            }
            
        }
        else {
            if let id = UUID.device() {
                fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                
            }
            
        }
       
        if fetch.predicate != nil {
            if let device = try? context.fetch(fetch).first {
                return device
                
            }
            
        }
        
        return nil
        
    }
    
    public func appStorageContext() -> NSManagedObjectContext? {
        if let container = CloudManager.container?.container {
            if CloudManager.shared.syncing == .completed {
                let context = container.newBackgroundContext()
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                return context
                
            }
            else {
                print("Still Syncing: \(CloudManager.shared.syncing.rawValue)")
                
            }
            
        }
        
        return nil
        
    }

    public func appDestoryEntity(_ type:CloudEntityType) {
        if let context = self.appStorageContext() {
            context.perform {
                do {
                    var request:NSFetchRequest<NSFetchRequestResult>
                    request = NSFetchRequest(entityName: type.rawValue)

                    let delete = NSBatchDeleteRequest(fetchRequest: request)
                    delete.resultType = .resultTypeObjectIDs
                    
                    try context.execute(delete)

                }
                catch {
                    
                }
                
            }
            
        }
        
    }
    
    public var appDeviceType:SystemDeviceTypes {
        #if os(macOS)
            let platform = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

            if let model = IORegistryEntryCreateCFProperty(platform, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
                if let type = String(data: model, encoding: .utf8)?.cString(using: .utf8) {
                    if String(cString: type).lowercased().contains("macbookpro") { return .macbookPro }
                    else if String(cString: type).lowercased().contains("macbookair") { return .macbookAir }
                    else if String(cString: type).lowercased().contains("macbook") { return .macbook }
                    else if String(cString: type).lowercased().contains("imac") { return .imac }
                    else if String(cString: type).lowercased().contains("macmini") { return .macMini }
                    else if String(cString: type).lowercased().contains("macstudio") { return .macStudio }
                    else if String(cString: type).lowercased().contains("macpro") { return .macPro }
                    else { return .unknown }
                  
                }
              
            }

            IOObjectRelease(platform)
        
        #elseif os(iOS)
            switch UIDevice.current.userInterfaceIdiom {
                case .phone:return .iphone
                case .pad:return .ipad
                default:return .unknown
                
            }
        
        #endif

        return .unknown
      
    }
    
    private func appDeviceMatch() -> String? {
        var parameters:[String] = []
        
        #if os(macOS)
        
        #elseif os (iOS)
            parameters.append(Device.init().osName)
            parameters.append(Device.init().osVersion ?? "0.0.0")
            parameters.append(Device.init().actualModel.marketingName)
            parameters.append(TimeZone.current.abbreviation() ?? "GMT")
        
        #endif

        if parameters.isEmpty == false {
            var output = parameters.joined(separator: "-")
            output = output.lowercased()
            output = output.replacingOccurrences(of: " ", with: "")
            
            return output
            
        }
        
        return nil

    }
    
    #if os(macOS)
        public func appToggleMenu(_ animate:Bool) {
            if animate {
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 1.0)) {
                    switch self.menu {
                        case .devices : self.menu = .settings
                        default : self.menu = .devices
                        
                    }
                }
                
            }
            else {
                switch self.menu {
                    case .devices : self.menu = .settings
                    default : self.menu = .devices
                    
                }
                
            }
            
        }

    #endif
            
}
