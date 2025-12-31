//
//  BBCloudManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/21/23.
//

import Foundation
import CloudKit
import CoreData
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
        let object = "BBDataObject"
        let container = NSPersistentCloudKitContainer(name: object)

        var directory: URL?
        var subdirectory: URL?

        guard let description = container.persistentStoreDescriptions.first else {
            #if DEBUG
                fatalError("No Description found")
            #else
                return nil
            #endif

        }

        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.ovatar.batteryboi")
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last {
            let parent = support.appendingPathComponent("BatteryBoi")

            do {
                try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)

                subdirectory = parent
                directory = parent.appendingPathComponent("\(object).sqlite")


            }
            catch {

            }

        }
        else {

        }

        if let directory = directory {
            DispatchQueue.global(qos: .userInitiated).async {
                if container.persistentStoreDescriptions.contains(where: { $0.url == description.url }) == false {
                    container.persistentStoreDescriptions.append(description)

                }

                container.viewContext.automaticallyMergesChangesFromParent = true
                let startTime = Date()

                container.loadPersistentStores { (storeDescription, error) in
                    let loadTime = Date().timeIntervalSince(startTime)

                    if let error = error {
                        DispatchQueue.main.async {
                            CloudManager.shared.syncing = .error

                            #if DEBUG
                                fatalError("iCloud Error \(error)")
                            #endif

                        }

                    }
                    else {
                        if let storeURL = storeDescription.url {
                            if let fileSize = try? FileManager.default.attributesOfItem(atPath: storeURL.path)[.size] as? Int {
                                let sizeMB = Double(fileSize) / 1_048_576

                                if sizeMB > 100 {

                                }

                            }
                            else {

                            }

                        }

                        DispatchQueue.main.async {
                            CloudManager.shared.syncing = .completed
                            AppManager.shared.updated = Date()

                        }

                    }

                }

            }

        }
        else {
            fatalError("Directory Not Found")

        }

        #if canImport(SwiftData)
        var storage: Any? = nil
        if #available(iOS 17.0, macOS 14.0, *) {
            storage = try? ModelContainer(for: BatteryEntry.self)
        }
        return .init(container: container, directory: directory, parent: subdirectory, storage: storage)
        #else
        return .init(container: container, directory: directory, parent: subdirectory)
        #endif

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

        NotificationCenter.default.addObserver(self, selector: #selector(cloudContextDidChange(notification:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)
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
            if userInfo[NSInsertedObjectsKey] != nil || userInfo[NSUpdatedObjectsKey] != nil || userInfo[NSDeletedObjectsKey] != nil {
                DispatchQueue.main.async {
                    AppManager.shared.updated = Date()

                }

            }

        }

    }
    
}
