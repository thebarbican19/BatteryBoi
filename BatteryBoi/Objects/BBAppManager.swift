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
    
    @Published var sessionid:UUID = UUID()
    @Published var counter = 0
    @Published var devices = Array<SystemDeviceObject>()
    @Published var selected:SystemDeviceObject? = nil
    @Published var updated:Date? = nil
    @Published var distribution:SystemDistribution = .direct

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
        
        if let receipt = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: receipt.path) {
            self.distribution = .appstore
            
        }
        
        $devices.receive(on: DispatchQueue.global()).debounce(for: .seconds(3), scheduler: RunLoop.main).sink { _ in
            self.appStoreDevice()
            
        }.store(in: &updates)
            
    }
    
    deinit {
        self.timer?.cancel()
        self.updates.forEach { $0.cancel() }
 
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
        
    private func appListDevices() {
        if let context = self.appStorageContext() {
            let fetch: NSFetchRequest<Devices> = Devices.fetchRequest()
            fetch.includesPendingChanges = true
            
            do {
                let list = try context.fetch(fetch)
                let mapped:[SystemDeviceObject] = list.compactMap({ .init($0) })

                DispatchQueue.main.async {
                    self.devices = mapped
                    
                }
                
            }
            catch {
                print("Error fetching Trained records: \(error)")
                
            }
            
        }
        
    }

    public func appStoreDevice(_ device:SystemDeviceObject? = nil) {
        if let context = self.appStorageContext() {
            context.perform {
                if let match = SystemDeviceObject.match(device, context: context) {
                    let fetch = Devices.fetchRequest() as NSFetchRequest<Devices>
                    fetch.includesPendingChanges = true
                    fetch.fetchLimit = 1
                    fetch.predicate = NSPredicate(format: "id == %@", match.id as CVarArg)
                    
                    do {
                        if let existing = try context.fetch(fetch).first {
                            existing.refreshed_on = Date()
                            
                            if existing.serial.empty {
                                existing.serial = device?.profile.serial
                                
                            }
                            
                            if existing.name.empty {
                                existing.name = device?.name
                                
                            }
                            
                            if existing.address.empty {
                                existing.address = device?.address
                                
                            }
                            
                            if let device = device, let type = SystemDeviceTypes.type(device.profile.model) {
                                existing.subtype = type.category.rawValue
                                existing.type = type.rawValue

                            }
       
                            if existing.vendor.empty {
                                existing.vendor = device?.profile.vendor
                                
                            }
                            
                            if let favourite = device?.favourite {
                                existing.favourite = favourite
                                
                            }
                            
                            if let notifications = device?.notifications {
                                existing.notifications = notifications
                                
                            }
                            
                            if let id = device?.id {
                                existing.id = id
                                
                            }
                            
                            try context.save()
                            
                        }
                        
                    }
                    catch {
                        
                    }
                    
                }
                else {
                    let store = Devices(context: context) as Devices
                    store.added_on = Date()
                    store.refreshed_on = Date()
                    store.order = Int16(self.devices.count + 1)
                    store.id = UUID()
                    store.notifications = true
                    store.hidden = false

                    if let device = device {
                        let type = SystemDeviceTypes.type(device.profile.model)
                        
                        store.primary = false
                        store.name = device.name
                        store.model = device.profile.model
                        store.serial = device.profile.serial
                        store.vendor = device.profile.vendor
                        store.type = type?.category.rawValue
                        store.subtype = type?.rawValue
                        store.address = nil
                        store.owner = self.appDevice(nil, context: context)?.id
                        
                    }
                    else {
                        if UserDefaults.main.object(forKey: SystemDefaultsKeys.deviceIdentifyer.rawValue) == nil {
                            store.model = SystemDeviceTypes.model
                            store.os = SystemDeviceTypes.os
                            store.subtype = SystemDeviceTypes.type.rawValue
                            store.type = SystemDeviceTypes.type.category.rawValue
                            store.primary = true
                            store.vendor = "Apple Inc"
                            store.product = SystemDeviceTypes.name(false)
                            store.serial = SystemDeviceTypes.serial
                            store.address = nil
                            store.name = SystemDeviceTypes.name(true)
                            
                            UserDefaults.save(.deviceIdentifyer, value: store.id?.uuidString)
                            UserDefaults.save(.deviceCreated, value: Date())
                            
                        }

                    }
                    
                    if store.model.empty == false || store.name.empty == false {
                        do {
                            try context.save()
                            
                        }
                        catch {
                            print("Saving Error - \(error)")
                            
                        }
                        
                    }
                    
                }
                
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
