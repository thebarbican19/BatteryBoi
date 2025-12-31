//
//  BBCloudManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/21/23.
//

import Foundation
import CloudKit
import UserNotifications
import Combine
import SwiftData

#if os(macOS)
import AppKit

#else
import UIKit

#endif


public class CloudManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var state: CloudState = .unknown
    @Published public var id: String? = nil
    @Published var syncing: CloudSyncedState = .syncing

    public static var shared = CloudManager()

    private var updates = Set<AnyCancellable>()

    static var container: CloudContainerObject? = {
        let identifier = "iCloud.com.ovatar.batteryboi"
        let group = "group.com.ovatar.batteryboi"

        do {
            let schema = Schema([BatteryEntryObject.self, DevicesObject.self, BatteryObject.self, AlertsObject.self, PushObject.self])
            let config = ModelConfiguration(schema: schema, groupContainer: .identifier(group), cloudKitDatabase: .private(identifier))
            let modelContainer = try ModelContainer(for: schema, configurations: config)

            DispatchQueue.main.async {
                CloudManager.shared.syncing = .completed
                AppManager.shared.updated = Date()
            }

            return CloudContainerObject(container: modelContainer)
        }
        catch {
            #if DEBUG
                print("Failed to create ModelContainer: \(error)")
                fatalError("SwiftData ModelContainer Error: \(error)")
            #else
                DispatchQueue.main.async {
                    CloudManager.shared.syncing = .error
                }
                return nil
            #endif
        }
    }()

    override init() {
        super.init()

        if let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String {
            CKContainer(identifier: id).accountStatus { status, error in
                if status == .available {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.cloudOwnerInformation()

                    }

                }
                else {
                    DispatchQueue.main.async {
                        self.state = .disabled

                    }

                }

            }

        }
        else {
            #if DEBUG
                fatalError("Cloud ID Enviroment is Missing")

            #endif

        }

        #if os(iOS)
            $state.removeDuplicates().delay(for: .seconds(0.2), scheduler: RunLoop.main).sink { state in
                if state == .enabled {
                    self.cloudSubscriptionsSetup(.alerts)
                    self.cloudSubscriptionsSetup(.events)

                }

            }.store(in: &updates)

        #endif

        NotificationCenter.default.addObserver(self, selector: #selector(cloudContextDidChange(notification:)), name: NSNotification.Name("NSManagedObjectContextDidSave"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cloudOwnerInformation), name: Notification.Name.CKAccountChanged, object: nil)

        #if os(macOS)
            NotificationCenter.default.addObserver(self, selector: #selector(cloudOwnerInformation), name: NSApplication.willBecomeActiveNotification, object: nil)
        #elseif os(iOS)
            NotificationCenter.default.addObserver(self, selector: #selector(cloudOwnerInformation), name: UIApplication.willEnterForegroundNotification, object: nil)
        #endif

    }

    public func cloudAllowNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .carPlay, .sound]) { granted, error in
                    DispatchQueue.main.async {
                        self.cloudOwnerInformation()

                    }

                }

            }
            else if settings.authorizationStatus == .denied {
                #if os(macOS)
                    DispatchQueue.main.async {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                #endif

            }

        }

    }

    @objc private func cloudOwnerInformation() {
        if let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String {
            CKContainer(identifier: id).accountStatus { status, error in
                if status == .available {
                    CKContainer(identifier: id).fetchUserRecordID { id, error in
                        if let id = id {
                            UNUserNotificationCenter.current().getNotificationSettings { settings in
                                DispatchQueue.main.async {
                                    switch settings.authorizationStatus {
                                        case .authorized: self.state = .enabled
                                        default: self.state = .blocked

                                    }

                                    self.id = id.recordName

                                }

                            }

                        }
                        else {
                            DispatchQueue.main.async {
                                self.state = .disabled
                            }
                        }

                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.state = .disabled
                    }
                }
            }

        }

    }

    private func cloudSubscriptionsSetup(_ type: CloudSubscriptionsType) {
        if let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String {
            let predicate = NSPredicate(value: true)
            let subscription = CKQuerySubscription(recordType: type.record, predicate: predicate, subscriptionID: type.identifyer, options: type.options)

            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true

            subscription.notificationInfo = info

            let database = CKContainer(identifier: id).privateCloudDatabase
            database.save(subscription) { (savedSubscription, error) in
                if let error = error {

                }
                else {

                }

            }

        }
        else {

        }

    }

    @objc func cloudContextDidChange(notification: Notification) {
        if let userInfo = notification.userInfo {
            if userInfo["inserted"] != nil || userInfo["updated"] != nil || userInfo["deleted"] != nil {
                DispatchQueue.main.async {
                    AppManager.shared.updated = Date()

                }

            }

        }

    }

}
