//
//  BatteryBoi__iOS_App.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 9/25/23.
//

import SwiftUI
import UIKit
import CloudKit
import CoreData
import ActivityKit
import BackgroundTasks

@main
struct BatteryBoi__iOS_App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationContainer()
            
        }
        
    }
    
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var shared = AppDelegate()
    
    private var activity:Activity<CloudNotifyAttributes>?
    private var state:Activity<CloudNotifyAttributes>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("\n\nApp Installed: \(AppManager.shared.appInstalled)\n\n")
        print("App Usage (Days): \(AppManager.shared.appUsage?.day ?? 0)\n\n")

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ovatar.batteryapp.refresh", using: nil) { task in
            self.applicationHandleAppRefresh(task: task as! BGAppRefreshTask)
            
        }
                
        return true
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.applicationScheduleAppRefresh()
        
    }
    
    func applicationScheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ovatar.batteryapp.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            
        }
        catch {
            print("Could not schedule app refresh: \(error)")
            
        }
        
    }
    
    func applicationHandleAppRefresh(task: BGAppRefreshTask) {
        self.applicationScheduleAppRefresh()
        
        task.expirationHandler = {
            BluetoothManager.shared.bluetoothStopScanning()
            
        }
        
        self.applicationBackgroundPushEvent(id: "") { _ in
            task.setTaskCompleted(success: true)
            
        }
        
        task.setTaskCompleted(success: true)
        
    }
    
    func applicationBackgroundPushEvent(id:String, completion: @escaping (Bool) -> Void) {
        let fetch: NSFetchRequest<Battery> = Battery.fetchRequest()
        fetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetch.fetchLimit = 1
        
        do {
            //let existing = try context.fetch(fetch)
        
            let content = UNMutableNotificationContent()
            content.title = "Batter Events \(id)"
            
//            if let sfx = alert.type.sfx?.rawValue {
//                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: sfx))
//                
//            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            //let request = UNNotificationRequest(identifier: "notification.\(alert.id.uuidString)", content: content, trigger: trigger)
            let request = UNNotificationRequest(identifier: "notification.", content: content, trigger: trigger)

            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                    completion(false)

                }
                else {
                    completion(true)
                    
                }
                
            }
            
        }
        catch {
            
        }
        
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            print("Components" ,components)
            
        }
        
        return true
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error" ,error)
        
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
        
        if let query = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification {
            AppManager.shared.updated = Date()
            if let id = query.subscriptionID {
                let task = UIApplication.shared.beginBackgroundTask {
                    
                }
                
                self.applicationBackgroundPushEvent(id: id, completion: { completion in
                    UIApplication.shared.endBackgroundTask(task)
                    
                    completionHandler(.newData)
                    
                })
                                                    
            }
            else {
                completionHandler(.failed)

            }
            
        }
        else {
            completionHandler(.noData)
            
        }
        
    }
        
}

