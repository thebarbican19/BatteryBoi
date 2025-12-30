//
//  BBAlertManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/19/23.
//

import Foundation
import CoreData

public class AlertManager: ObservableObject {
    static var shared = AlertManager()

    @Published var alerts = Array<SystemPushObject>()

    init() {
        self.alertTypeList()

    }

    private func alertTypeList() {
        if let context = AppManager.shared.appStorageContext() {
            let fetch: NSFetchRequest<Push> = Push.fetchRequest()
            fetch.includesPendingChanges = true

            do {
                let list = try context.fetch(fetch)
                if list.isEmpty {
                    self.alertReset()

                }
                else {
                    let mapped: [SystemPushObject] = list.compactMap({ .init($0) })

                    DispatchQueue.main.async {
                        self.alerts = mapped

                    }

                }

            }
            catch {
                print("Error fetching Trained records: \(error)")

            }

        }

    }

    private func alertTrigger(alert: SystemAlertObject) {
        #if canImport(WindowManager)

            WindowManager.shared.windowOpen(alert: alert.type, device: alert.event.device)

        #else

        #endif

    }

    public func alertReset() {
        if let context = AppManager.shared.appStorageContext() {
            context.perform {
                do {
                    var request: NSFetchRequest<NSFetchRequestResult>
                    request = NSFetchRequest(entityName: "Push")

                    let delete = NSBatchDeleteRequest(fetchRequest: request)
                    delete.resultType = .resultTypeObjectIDs

                    try context.execute(delete)

                    for percent in [1, 5, 15, 25] {
                        self.alertTypeCreate(.deviceDepleting, value: percent, custom: false)

                    }

                    self.alertTypeCreate(.chargingBegan, value: nil, custom: false)
                    self.alertTypeCreate(.chargingStopped, value: nil, custom: false)
                    self.alertTypeCreate(.chargingComplete, value: nil, custom: false)

                }
                catch {

                }

            }

        }

    }

    func alertCreate(event: SystemEventObject, force: SystemAlertTypes? = nil, context: NSManagedObjectContext) {
        do {
            var type: SystemAlertTypes? = nil

            let fetch = Alerts.fetchRequest() as NSFetchRequest<Alerts>
            fetch.predicate = NSPredicate(format: "SELF.event.id == %@", event.id as CVarArg)
            fetch.includesPendingChanges = true

            guard let system = UserDefaults.main.object(forKey: SystemDefaultsKeys.deviceIdentifyer.rawValue) as? String else {
                return

            }

            if let _ = event.device {
                if self.alerts.first(where: { $0.percentage == event.percentage && $0.type == .deviceDepleting }) != nil {
                    type = .deviceDepleting

                }

            }
            else {
                if event.percentage == BatteryManager.shared.max && BatteryManager.shared.charging == .charging {
                    type = .chargingComplete

                }
                else {
                    if self.alerts.first(where: { $0.percentage == event.percentage && $0.type == .deviceDepleting }) != nil {
                        type = .deviceDepleting

                    }

                }

                if let force = force {
                    if force == .deviceOverheating {
                        if event.thermal?.state == .suboptimal {
                            type = .deviceOverheating

                        }

                    }
                    else {
                        type = force

                    }

                }

            }

            guard let type = type else {
                return

            }

            if let existing = try context.fetch(fetch).first {
                existing.triggered_on = Date()
                existing.type = type.rawValue

                try context.save()

                if let converted = SystemAlertObject(existing) {
                    self.alertTrigger(alert: converted)

                }

            }
            else {
                let store = Alerts(context: context) as Alerts
                store.id = UUID()
                store.triggered_on = Date()
                store.event = event.entity
                store.type = type.rawValue
                store.local = type.local
                store.owner = UUID(uuidString: system) ?? UUID()

                try context.save()

                if let converted = SystemAlertObject(store) {
                    self.alertTrigger(alert: converted)

                }

            }

        }
        catch {

        }

    }

    public func alertTypeMultiple(_ multiple: Int) {
        if multiple > 4 {
            for i in 1...99 {
                if i % multiple == 0 {
                    self.alertTypeCreate(.deviceDepleting, value: i)

                }

            }

        }

    }

    public func alertTypeCreate(_ type: SystemAlertTypes, value: Int?, custom: Bool = true) {
        do {
            if let context = AppManager.shared.appStorageContext() {
                let fetch = Push.fetchRequest() as NSFetchRequest<Push>
                fetch.includesPendingChanges = true
                if let value = value {
                    fetch.predicate = NSPredicate(format: "type == %d && percent == %d", type.rawValue, value)

                }
                else {
                    fetch.predicate = NSPredicate(format: "type == %d", type.rawValue)

                }

                if try context.fetch(fetch).first == nil {
                    let store = Push(context: context) as Push
                    store.id = UUID()
                    store.added_on = Date()
                    store.custom = custom
                    store.type = type.rawValue

                    if let value = value {
                        store.percent = Int16(value)

                    }

                    try context.save()

                }

            }

        }
        catch {

        }

    }

    public func alertTypeDelete(_ type: SystemAlertTypes, value: Int?) {
        do {
            if let context = AppManager.shared.appStorageContext() {
                let fetch = Push.fetchRequest() as NSFetchRequest<Push>
                fetch.includesPendingChanges = true
                if let value = value {
                    fetch.predicate = NSPredicate(format: "type == %d && percent == %d", type.rawValue, value)

                }
                else {
                    fetch.predicate = NSPredicate(format: "type == %d", type.rawValue)

                }

                if let existing = try context.fetch(fetch).first {
                    context.delete(existing)

                    try context.save()

                }

            }

        }
        catch {

        }

    }

}
