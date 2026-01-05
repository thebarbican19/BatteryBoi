//
//  BatteryBoi__iOS_App.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 9/25/23.
//

import SwiftUI
import UIKit
import CloudKit
import ActivityKit
import BackgroundTasks
import SwiftData
import UserNotifications

@main
struct BatteryBoi__iOS_App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if let container = CloudManager.container?.container {
                NavigationContainer().modelContainer(container)

            }
			else {
                NavigationContainer()

            }

        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                HeartbeatManager.shared.heartbeatStart()
				
            }
			
        }

    }

}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var shared = AppDelegate()
    
    private var activity:Activity<CloudNotifyAttributes>?
    private var state:Activity<CloudNotifyAttributes>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        BluetoothManager.shared.bluetoothAuthorization(true)

        print("\n\nApp Installed: \(AppManager.shared.appInstalled)\n\n")
        print("App Usage (Days): \(AppManager.shared.appUsage?.day ?? 0)\n\n")

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ovatar.batteryapp.refresh", using: nil) { task in
            self.applicationHandleAppRefresh(task: task as! BGAppRefreshTask)
            
        }
                
        return true
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {

    }
    
    func applicationScheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ovatar.batteryapp.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            
        }
        catch {
            print("Could not schedule app refresh: \(error)")
            
        }
        
    }
    
    func applicationHandleAppRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            BluetoothManager.shared.bluetoothStopScanning()

        }

        task.setTaskCompleted(success: true)

    }
    
    func applicationBackgroundPushEvent(subscriptionId: String, completion: @escaping (Bool) -> Void) {
        guard subscriptionId == "sub.alert" else {
            print("⏭️ Skipping background event for non-alert subscription: \(subscriptionId)")
            completion(true)
            return

        }

        print("🔔 Processing alert notification for subscription: \(subscriptionId)")

        if let context = AppManager.shared.appStorageContext() {
            do {
                let descriptor = FetchDescriptor<AlertsObject>(sortBy: [SortDescriptor(\.triggeredOn, order: .reverse)])
                let alerts = try context.fetch(descriptor)

                guard let latestAlert = alerts.first else {
                    print("⚠️ No recent alert found")
                    completion(true)
                    return
                }

                guard let triggeredOn = latestAlert.triggeredOn else {
                    print("⚠️ No recent alert found")
                    completion(true)
                    return
                }

                let timeSinceTriggered = Date().timeIntervalSince(triggeredOn)
                guard timeSinceTriggered < 60 else {
                    print("⏰ Alert is too old to notify (triggered \(timeSinceTriggered)s ago)")
                    completion(true)
                    return

                }

                if let converted = AppAlertObject(latestAlert) {
                    let content = UNMutableNotificationContent()
                    content.title = converted.type.description
                    content.body = "Battery: \(converted.event.percentage)%"

                    if let sfx = converted.type.sfx?.rawValue {
                        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sfx))

                    }

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: "notification.\(converted.id.uuidString)", content: content, trigger: trigger)

                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("❌ Error scheduling notification: \(error)")
                            completion(false)

                        }
                        else {
                            print("✅ Notification scheduled successfully for alert: \(converted.type.description)")
                            completion(true)

                        }

                    }

                }
                else {
                    completion(true)

                }

            }
            catch {
                print("❌ Error fetching alerts: \(error)")
                completion(false)

            }

        }
        else {
            completion(false)

        }

    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            print("Components" ,components)
            
        }
        
        return true
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
        
    }
    
//    func applicationHandleActivity(_ event:Events?) {
//        do {
////            if let event = event, let timestamp = event.timestamp {
////                let stale:Date = Date(timeIntervalSinceNow: 60 * 20)
////                //let attributes = CloudNotifyAttributes(device: event.device?.name ?? event.device?.id ?? "UNKNOWN")
////                let state = CloudNotifyAttributes.ContentState.init(battery: Int(event.charge), charging: false, timestamp: timestamp)
////                let content = ActivityContent(state: state, staleDate: stale)
////                
////                if self.activity == nil {
////                    self.activity = try Activity.request(attributes: attributes, content: content)
////
////                }
////                else {
////                    Task {
////                        await self.activity?.update(content)
////
////                    }
////                    
////                }
////                
////            }
////            else {
////                Task {
////                    await self.activity?.end(self.activity?.content, dismissalPolicy: .immediate)
////
////                }
////                
////            }
//        
//        }
//        catch {
//            
//        }
//    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📩 Received remote notification: \(userInfo)")

        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            print("❌ Not a CloudKit notification")
            completionHandler(.noData)
            return
        }

        AppManager.shared.updated = Date()

        var subscriptionID: String?

        if let queryNotification = notification as? CKQueryNotification {
            subscriptionID = queryNotification.subscriptionID
            print("✅ Received CKQueryNotification with subscription ID: \(subscriptionID ?? "nil")")
        }
        else if let databaseNotification = notification as? CKDatabaseNotification {
            subscriptionID = databaseNotification.subscriptionID
            print("✅ Received CKDatabaseNotification (SwiftData) with subscription ID: \(subscriptionID ?? "nil")")
        }
        else {
            print("⚠️ Received other CloudKit notification type: \(type(of: notification))")
        }

        if let id = subscriptionID {
            if id == "sub.alert" {
                let task = UIApplication.shared.beginBackgroundTask {
                    print("⚠️ Background task expired")

                }

                self.applicationBackgroundPushEvent(subscriptionId: id, completion: { completion in
                    print("🏁 Background push event completion: \(completion)")
                    UIApplication.shared.endBackgroundTask(task)

                    completionHandler(.newData)

                })

            }
            else {
                print("⏭️ Skipping notification for non-alert subscription: \(id)")
                completionHandler(.newData)

            }

        }
        else {
            print("⚠️ CloudKit notification received with no subscription ID")
            completionHandler(.noData)

        }

    }
        
}

