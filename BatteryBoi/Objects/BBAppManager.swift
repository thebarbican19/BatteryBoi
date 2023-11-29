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

class AppManager:ObservableObject {
    static var shared = AppManager()
    
    @Published var counter = 0
    @Published var list = Array<SystemDeviceObject>()
    @Published var device:SystemDeviceObject? = nil
    @Published var updated:Date? = nil
        
    #if os(macOS)
        @Published var menu:SystemMenuView = .devices
        @Published var profile:SystemProfileObject? = nil
        @Published var alert:HUDAlertTypes? = nil
    
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
           
        #if os(macOS)
            if #available(macOS 13.0, *) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if self.appDistribution() == .direct {
                        self.profile = self.appProfile(force: false)
                        
                    }
                    
                }
                
            }
        
        #endif
                
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.appStoreDevice()
            
        }
        
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
                if let peripheral = peripheral {
                    if let device = self.appDevice(peripheral, context: context), let battery = battery, let name = device.name {
                        let fetch = Events.fetchRequest() as NSFetchRequest<Events>
                        fetch.includesPendingChanges = true
                        fetch.predicate = NSPredicate(format: "SELF.state == %@ && SELF.device.name == %@ && SELF.charge == %d" ,state.rawValue, name ,Int64(battery))
                        
                        do {
                            if try context.fetch(fetch).first == nil {
                                let store = Events(context: context) as Events
                                store.id = UUID()
                                store.timestamp = Date()
                                store.state = state.rawValue
                                store.charge = Int64(battery)
                                store.device = device
                                store.reporter = self.appDevice(peripheral, context: context)
                                store.mode = BatteryModeType.normal.rawValue
                                      
                                if let last = self.appLatestEvent(state, device: peripheral, context: context) {
                                    switch last.charge {
                                        case 25 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case 15 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case 10 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case 5 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case 1 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case store.charge : store.notify = StatsActivityNotificationType.background.rawValue
                                        default : store.notify = StatsActivityNotificationType.none.rawValue
                                        
                                    }
                                    
                                }
                                
                                try context.save()
                                
                            }
                            
                        }
                        catch {
                            print("Error" ,error)
                            
                        }
                        
                    }
                    
                }
                else {
                    if let device = self.appDevice(nil, context: context) {
                        let battery = Int64(BatteryManager.shared.percentage)

                        let fetch = Events.fetchRequest() as NSFetchRequest<Events>
                        fetch.includesPendingChanges = true
                        fetch.predicate = NSPredicate(format: "SELF.state == %@ && SELF.device.id == %@ && SELF.charge == %d" ,state.rawValue, device.id! as CVarArg ,Int64(battery))
                        
                        do {
                            if try context.fetch(fetch).first == nil && battery >= 0 {
                                let os = ProcessInfo.processInfo.operatingSystemVersion
                                
                                let store = Events(context: context) as Events
                                store.id = UUID()
                                store.timestamp = Date()
                                store.state = state.rawValue
                                store.charge = Int64(battery)
                                store.device = device
                                store.reporter = self.appDevice(nil, context: context)
                                store.mode = BatteryManager.shared.saver.rawValue
                                
                                if let version = Float("\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)") {
                                    store.version = version

                                }
                                
                                if let last = self.appLatestEvent(state, device: peripheral, context: context) {
                                    switch last.charge {
                                        case 25 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case 15 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case 10 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case 5 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case 1 : store.notify = StatsActivityNotificationType.alert.rawValue
                                        case store.charge : store.notify = StatsActivityNotificationType.background.rawValue
                                        default : store.notify = StatsActivityNotificationType.none.rawValue
                                        
                                    }

                                }
                                
                                try context.save()
                                
                            }
                            
                        }
                        catch {
                            print("Error" ,error)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
  
    public func appWattageStore() {
        #if os(macOS)
            if let context = self.appStorageContext() {
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
                                store.device = self.appDevice(nil, context: context)
                                store.wattage = BatteryManager.shared.powerHourWattage() ?? 0.0
                                
                                try context.save()
                                
                            }
                            
                        }
                        catch {
                            
                        }
                        
                    }
                    
                }
                
            }
        
        #endif
        
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
            fetch.predicate = NSPredicate(format: "name != %@", "")
            
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
                var predicates = Array<NSPredicate>()
                
                if let device = device {
                    predicates.append(NSPredicate(format: "name == %@", device.name))
                    
                }
                else {
                    if let id = UUID.device() {
                        predicates.append(NSPredicate(format: "id == %@", id as CVarArg))
                        
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
                            
                            if device == nil {
                                store?.id = UUID.device()

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
                                store?.name = device.name
                                store?.vendor = device.profile?.hardware
                                store?.type = "TBA"
                                store?.primary = false
                                
                            }
                            else {
                                let type = AppManager.shared.appDeviceType
                                
                                store?.id = UUID.device()
                                store?.subtype = type.name(false)
                                store?.type = type.category.rawValue
                                store?.name = type.name(true)
                                store?.primary = true
                                store?.vendor = "Apple Inc"
                                store?.product = type.name(false)
                                store?.serial = "TBA"
                                store?.address = ""
                                
                            }
                            
                        }
                        
                        if store?.name != nil {
                            print("Saving" ,store)
                            
                            try context.save()
                            
                        }
                        
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
    
    private func appStorageContext() -> NSManagedObjectContext? {
        if let container = CloudManager.container.container {
            let context = container.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            return context
            
        }
        
        return nil
        
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
    
    public func appDistribution() -> SystemDistribution {
        #if os(macOS)
            if let response = ProcessManager.shared.processWithArguments("/usr/bin/codesign", arguments:["-dv", "--verbose=4", Bundle.main.bundlePath], whitespace: false) {
                if response.contains("Authority=Apple Mac OS Application Signing") {
                    return .appstore

                }
                
            }
            
            return .direct
        
        #elseif os(iOS)
            if Bundle.main.appStoreReceiptURL == nil {
                return .direct

            }
            else {
                return .appstore

            }
        
        #endif
            
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
    
    #if os(macOS)
        private func appProfile(force:Bool = false) -> SystemProfileObject? {
            if let payload = UserDefaults.main.object(forKey: SystemDefaultsKeys.profilePayload.rawValue) as? String {

                if let object =  try? JSONDecoder().decode([SystemProfileObject].self, from: Data(payload.utf8)) {
                    return object.first
                    
                }
                
            }
            else {
                if let response = ProcessManager.shared.processWithScript("BBProfileScript") {
                    UserDefaults.save(.profilePayload, value: response)
                    UserDefaults.save(.profileChecked, value: Date())
                    
                    if let object = try? JSONDecoder().decode([SystemProfileObject].self, from: Data(response.utf8)) {
                        if let id = object.first?.id, let display = object.first?.display {
                            let first = SystemProfileObject(id: id, display: display)
                            
                            if let channel = Bundle.main.infoDictionary?["SD_SLACK_CHANNEL"] as? String  {
                                EnalogManager.main.ingest(SystemEvents.userProfile, description: "Profile Found: \(display)", metadata: object, channel:.init(.slack, id: channel))
                                
                            }
                            
                            return first
                            
                        }
                        
                    }
                    
                }
                
            }
                
            return nil
            
        }
    
    #endif
            
}
