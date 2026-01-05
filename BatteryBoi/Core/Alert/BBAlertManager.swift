//
//  BBAlertManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/19/23.
//

import Foundation
import SwiftData

public class AlertManager: ObservableObject {
    static var shared = AlertManager()

    @Published var alerts = Array<AppPushObject>()
    private var lastTriggeredAlert: (eventId: UUID, type: String, triggeredOn: Date)?

    init() {
        self.alertTypeList()

    }

    private func alertTypeList() {
        if let context = AppManager.shared.appStorageContext() {
            let descriptor = FetchDescriptor<PushObject>()

            do {
                let list = try context.fetch(descriptor)
                if list.isEmpty {
                    self.alertReset()

                }
                else {
                    let mapped: [AppPushObject] = list.compactMap({ .init($0) })

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

    private func alertTrigger(alert: AppAlertObject) {
        #if canImport(WindowManager)

            WindowManager.shared.windowOpen(alert: alert.type, device: alert.event.device)
            self.alertTriggerMacOS(alert: alert)

        #else

        #endif

    }

    private func alertTriggerMacOS(alert: AppAlertObject) {
        print("[DEBUG] macOS Alert Triggered: \(alert.type.rawValue)")

    }

    public func alertReset() {
        if let context = AppManager.shared.appStorageContext() {
            do {
                let descriptor = FetchDescriptor<PushObject>()
                let items = try context.fetch(descriptor)
                for item in items {
                    context.delete(item)
                }
                try context.save()

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

    func alertCreate(event: AppEventObject, force: AppAlertTypes? = nil, context: ModelContext) {
        do {
            var type: AppAlertTypes? = nil

            let eventId: UUID? = event.id
            var descriptor = FetchDescriptor<AlertsObject>(predicate: #Predicate { $0.event?.id == eventId })
            descriptor.fetchLimit = 1

            guard let system = UserDefaults.main.object(forKey: AppDefaultsKeys.deviceIdentifyer.rawValue) as? String else {
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


            let fetchStart = Date()
            if let existing = try context.fetch(descriptor).first {
                let fetchTime = Date().timeIntervalSince(fetchStart)

                if let lastAlert = self.lastTriggeredAlert, lastAlert.eventId == existing.event?.id, lastAlert.type == type.rawValue {
                    return

                }

                existing.triggeredOn = Date()
                existing.type = type.rawValue

                let saveStart = Date()
                try context.save()
                let saveTime = Date().timeIntervalSince(saveStart)

                if saveTime > 1.0 {

                }

            }
            else {
                let store = AlertsObject()
                store.id = UUID()
                store.triggeredOn = Date()
                store.event = event.entity
                store.type = type.rawValue
                store.local = type.local
                store.owner = UUID(uuidString: system) ?? UUID()

                context.insert(store)
                let saveStart = Date()
                try context.save()
                let saveTime = Date().timeIntervalSince(saveStart)

                if saveTime > 1.0 {

                }

                if let converted = AppAlertObject(store) {
                    self.lastTriggeredAlert = (eventId: store.event?.id ?? UUID(), type: store.type ?? "", triggeredOn: Date())
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

    public func alertTypeCreate(_ type: AppAlertTypes, value: Int?, custom: Bool = true) {
        do {
            if let context = AppManager.shared.appStorageContext() {
                let typeRawValue: String? = type.rawValue
                var descriptor: FetchDescriptor<PushObject>
                if let value = value {
                    let percentValue: Int? = value
                    descriptor = FetchDescriptor<PushObject>(predicate: #Predicate { $0.type == typeRawValue && $0.percent == percentValue })
                }
                else {
                    descriptor = FetchDescriptor<PushObject>(predicate: #Predicate { $0.type == typeRawValue })
                }

                if try context.fetch(descriptor).first == nil {
                    let store = PushObject()
                    store.id = UUID()
                    store.addedOn = Date()
                    store.custom = custom
                    store.type = type.rawValue

                    if let value = value {
                        store.percent = value

                    }

                    context.insert(store)
                    try context.save()

                }

            }

        }
        catch {

        }

    }

    public func alertTypeDelete(_ type: AppAlertTypes, value: Int?) {
        do {
            if let context = AppManager.shared.appStorageContext() {
                let typeRawValue: String? = type.rawValue
                var descriptor: FetchDescriptor<PushObject>
                if let value = value {
                    let percentValue: Int? = value
                    descriptor = FetchDescriptor<PushObject>(predicate: #Predicate { $0.type == typeRawValue && $0.percent == percentValue })
                }
                else {
                    descriptor = FetchDescriptor<PushObject>(predicate: #Predicate { $0.type == typeRawValue })
                }

                if let existing = try context.fetch(descriptor).first {
                    context.delete(existing)

                    try context.save()

                }

            }

        }
        catch {

        }

    }

    public func alertCreateTest(type: AppAlertTypes, context: ModelContext, completion: @escaping (UUID?) -> Void) {
        let event = BatteryObject()
        event.id = UUID()
        event.created = Date()
        event.session = AppManager.shared.sessionid

        if type == .chargingComplete || type == .chargingBegan {
            event.percent = BatteryManager.shared.max
            event.state = BatteryChargingState.charging.rawValue

        }
        else if type == .chargingStopped {
            event.percent = 95
            event.state = BatteryChargingState.battery.rawValue

        }
        else if type == .deviceDepleting {
            event.percent = 15
            event.state = BatteryChargingState.battery.rawValue

        }
        else if type == .deviceOverheating {
            event.percent = 50
            event.temprature = 45
            event.state = BatteryChargingState.battery.rawValue

        }
        else {
            event.percent = BatteryManager.shared.percentage
            event.state = BatteryManager.shared.charging.rawValue

        }

        context.insert(event)
        try? context.save()

        guard let appEvent = AppEventObject(event) else {
            completion(nil)
            return

        }

        self.alertCreate(event: appEvent, force: type, context: context)

        let typeRawValue = type.rawValue
        let descriptor = FetchDescriptor<AlertsObject>(predicate: #Predicate { $0.type == typeRawValue })
        let createdAlert = try? context.fetch(descriptor).first
        let alertId = createdAlert?.id

        completion(alertId)

        if let alertId = alertId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if let context = AppManager.shared.appStorageContext() {
                    let descriptor = FetchDescriptor<AlertsObject>(predicate: #Predicate { $0.id == alertId })
                    if let alertToDelete = try? context.fetch(descriptor).first {
                        context.delete(alertToDelete)
                        try? context.save()
                    }
                }
            }
        }

    }

}
