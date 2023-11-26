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

class AppManager:ObservableObject {
    static var shared = AppManager()
    
    @Published var counter = 0
    @Published var list = Array<SystemDeviceObject>()
    @Published var device:SystemDeviceObject? = nil
    @Published var polled:Date? = nil
    
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
        
        $list.removeDuplicates().sink { item in

        }.store(in: &updates)

        $polled.removeDuplicates().sink { timestamp in
            //!! check for changes to polling

        }.store(in: &updates)
        
        DispatchQueue.global().async {
            self.appStoreDevice()
            self.appListDevices()
            
        }
    
    }
    
    deinit {
        self.timer?.cancel()
        self.updates.forEach { $0.cancel() }
 
    }
    
    public func appStoreDevice(_ device:BluetoothObject? = nil, favourite:Bool? = nil, hidden:Bool? = nil, notifications:Bool? = nil) {
        if let context = self.appStorageContext() {
            context.performAndWait {
                var predicates = Array<NSPredicate>()
                
                if let address = device?.address {
                    predicates.append(NSPredicate(format: "address == %@", address))
                    
                }
                
                if let id = device?.id {
                    predicates.append(NSPredicate(format: "id == %@", id as CVarArg))
                    
                }
                
                let fetch = Devices.fetchRequest() as NSFetchRequest<Devices>
                fetch.includesPendingChanges = true
                fetch.predicate = NSCompoundPredicate(type: .or, subpredicates: predicates)
                
                do {
                    var store:Devices?
                    if let existing = try context.fetch(fetch).first {
                        store = existing
                        store?.refreshed_on = Date()
                        
                        if let notifications = notifications {
                            store?.notifications = notifications

                        }
                        
                        if let device = device?.name {
                            store?.name = device
                            
                        }

                        if let hidden = hidden {
                            store?.hidden = hidden
                            
                        }
                        
                        if let favourite = favourite {
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
                            store?.name = device.name
                            store?.vendor = device.vendor
                            store?.type = "TBA"
                            store?.primary = false

                        }
                        else {
                            store?.id = UUID.device()
                            store?.subtype = AppManager.shared.appDeviceType.name(false)
                            store?.type = AppManager.shared.appDeviceType.category.rawValue
                            store?.name = AppManager.shared.appDeviceType.name(true)
                            store?.primary = true
                            store?.vendor = "Apple Inc"
                            store?.product = AppManager.shared.appDeviceType.name(false)
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
    
    public func appStoreEvent(_ state:StatsStateType, device:BluetoothObject?, notification:StatsActivityNotificationType = .background) {
        if let context = self.appStorageContext() {
            context.performAndWait {
                let expiry = Date().addingTimeInterval(-2 * 60)
                var charge:Int64 = 100
                var mode:BatteryModeType = .normal
                if let percent = device {
                    //charge = Int64(percent.battery.percent ?? 100)
                    mode = .normal
                    
                }
                else {
                    charge = Int64(BatteryManager.shared.percentage)
                    mode = BatteryManager.shared.saver

                }
                
                if let device = self.appDevice(device, context: context), let id = device.id {
                    let fetch = Events.fetchRequest() as NSFetchRequest<Events>
                    fetch.includesPendingChanges = true
                    fetch.predicate = NSPredicate(format: "SELF.state == %@ && SELF.device.id == %@ && SELF.charge == %d &&  SELF.timestamp > %@" ,state.rawValue, id as CVarArg ,charge ,expiry as NSDate)
                    
                    do {
                        if try context.fetch(fetch).first == nil {
                            let store = Events(context: context) as Events
                            store.timestamp = Date()
                            store.state = state.rawValue
                            store.charge = charge
                            store.notify = notification.rawValue
                            store.device = device
                            store.reporter = self.appDevice(nil, context: context)
                            store.mode = mode.rawValue
                            
                            print("store" ,store)
                            
                            try context.save()
                            
                        }
                        
                    }
                    catch {
                        print("Error" ,error)
                        
                    }
                    
                }
                else {
                    
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
    
    
    private func appDevice(_ device:BluetoothObject? ,context:NSManagedObjectContext) -> Devices? {
        let fetch = Devices.fetchRequest() as NSFetchRequest<Devices>
        fetch.includesPendingChanges = true
        fetch.fetchLimit = 1
        
        if let id = device?.id {
            fetch.predicate = NSPredicate(format: "device.id == %@", id as CVarArg)
            
        }
        else if let id = UUID.device() {
            fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
        }
        
        if fetch.predicate != nil {
            if let device = try? context.fetch(fetch).first {
                return device
                
            }
            
        }
        
        return nil
        
    }
    
    private func appListDevices() {
        if let context = self.appStorageContext() {
            let fetch: NSFetchRequest<Devices> = Devices.fetchRequest()
            
            do {
                let list = try context.fetch(fetch)
                //let mapped = list.compactMap({ SystemDeviceObject($0) })

//                DispatchQueue.main.async {
//                    self.list = mapped
//                    
//                }

//                print("trained" ,mapped)
                
            }
            catch {
                print("Error fetching Trained records: \(error)")
                
            }
            
        }
        
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
