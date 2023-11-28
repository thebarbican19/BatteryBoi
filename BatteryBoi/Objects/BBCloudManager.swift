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

class CloudManager:ObservableObject {
    @Published var state:CloudState = .unknown
    @Published var id:String? = nil

    static var shared = CloudManager()

    private var updates = Set<AnyCancellable>()

    static var container: CloudContainerObject = {
        let object = "BBDataObject"
        let container = NSPersistentCloudKitContainer(name: object)
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("No Description found")
            
        }
        
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.ovatar.batteryboi")
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        var directory: URL?
        var subdirectory: URL?
        
        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last {
            let parent = support.appendingPathComponent("BatteryBoi")
                        
            do {
                try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)
                
                let file = parent.appendingPathComponent("\(object).sqlite")
                directory = file
                
                print("\n\nSQL File: \(file.absoluteString)\n\n")
                
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: file)]
                
                subdirectory = parent
                
            }
            catch {
                print("Error creating or setting SQLite store URL: \(error)")
                
            }
            
        }
        else {
            print("Error retrieving Application Support directory URL.")
            
        }

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            print("\n\nstoreDescription" ,storeDescription)
            if let error = error {
                fatalError("Unresolved error \(error)")
                
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
        if let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String  {
            CKContainer(identifier: id).accountStatus { status, error in
                if status == .available {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.cloudOwnerInformation()
                        
                    }
                    
                }
                
            }
                        
        }
        else {
            #if DEBUG
                fatalError("Cloud ID Enviroment is Missing")

            #endif

        }
        
        $state.removeDuplicates().delay(for: .seconds(0.2), scheduler: RunLoop.main).sink { state in
            if state == .enabled {
                self.cloudSubscriptionsSetup(.device)
                self.cloudSubscriptionsSetup(.events)

            }
            
        }.store(in: &updates)
        
        NotificationCenter.default.addObserver(self, selector: #selector(cloudContextDidChange(notification:)), name: .NSManagedObjectContextObjectsDidChange, object: nil)

    }
    
    public func cloudAllowNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options:[.alert, .carPlay, .sound]) { granted, error in
                    DispatchQueue.main.async {
                        self.cloudOwnerInformation()

                    }
                    
                }
                
            }
            else if settings.authorizationStatus != .authorized {
                //open settings
                
            }
            
        }
        
    }
    
    public func cloudNotification(_ notification: CKQueryNotification) {
        if let record = notification.recordID {
            print("record" ,record)
            
        }

    }
    
    private func cloudOwnerInformation() {
        if let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String  {
            CKContainer(identifier: id).fetchUserRecordID { id, error in
                if let id = id {
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        DispatchQueue.main.async {
                            switch settings.authorizationStatus {
                                case .authorized: self.state = .enabled
                                default : self.state = .blocked
                                
                            }
                            
                            self.id = id.recordName
                            
                        }
                                                
                    }
                    
                    print("\n\niCloud ID" ,id.recordName)

                }
                                
            }
            
        }
        
    }
    
    private func cloudSubscriptionsSetup(_ type:CloudSubscriptionsType) {
        if let id = Bundle.main.infoDictionary?["ENV_ICLOUD_ID"] as? String  {
            //let predicate = NSPredicate(format: "NOTIFY == %@", ActivityNotificationType.background.rawValue)
            let predicate = NSPredicate(value: true)
            let subscription = CKQuerySubscription(recordType: type.record, predicate: predicate, subscriptionID: type.identifyer, options:type.options)
            
            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true
            
            subscription.notificationInfo = info
            
            let database = CKContainer(identifier: id).privateCloudDatabase
            database.save(subscription) { (savedSubscription, error) in
                if let error = error {
                    print("An error occurred: \(error.localizedDescription)")
                    
                }
                else {
                    print("Subscription saved successfully!")
                    
                }
                
            }
            
        }
        
    }
    
    @objc func cloudContextDidChange(notification: Notification) {
        if let userInfo = notification.userInfo {
            if userInfo[NSInsertedObjectsKey] != nil || userInfo[NSUpdatedObjectsKey] != nil || userInfo[NSDeletedObjectsKey] != nil {
                DispatchQueue.main.async {
                    //AppManager.shared.updated = Date()

                }
                
            }
            
        }
        
    }
    
}
