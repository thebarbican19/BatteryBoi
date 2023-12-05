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
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        
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
        
        self.applicationSendBackgroundEvent { success in
            task.setTaskCompleted(success: success)
            
        }
        
        task.setTaskCompleted(success: true)
        
    }
    
    func applicationSendBackgroundEvent(completion: @escaping (Bool) -> Void) {
        BatteryManager.shared.powerForceRefresh()
        BluetoothManager.shared.bluetoothAuthorization()
        
        self.applicationFetchLatestEvent { event in
            if let event = event {
                completion(true)
                
            }
            else {
                completion(false)
                
            }
            
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
    
    func applicationHandleActivity(_ event:Events?) {
        do {
            if let event = event, let timestamp = event.timestamp {
                let stale:Date = Date(timeIntervalSinceNow: 60 * 20)
                let attributes = CloudNotifyAttributes(device: event.device?.name ?? event.device?.match ?? "Uknown")
                let state = CloudNotifyAttributes.ContentState.init(battery: Int(event.charge), charging: false, timestamp: timestamp)
                let content = ActivityContent(state: state, staleDate: stale)
                
                if self.activity == nil {
                    self.activity = try Activity.request(attributes: attributes, content: content)

                }
                else {
                    Task {
                        await self.activity?.update(content)

                    }
                    
                }
                
            }
            else {
                Task {
                    await self.activity?.end(self.activity?.content, dismissalPolicy: .immediate)

                }
                
            }
        
        }
        catch {
            
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let _ = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification {
            AppManager.shared.updated = Date()
            
            let task = UIApplication.shared.beginBackgroundTask {
                
            }
            
            self.applicationFetchLatestEvent { event in
                if let event = event {
                    self.applicationHandleActivity(event)
                    
                    UIApplication.shared.endBackgroundTask(task)
                    
                    completionHandler(.newData)
                    
                }
                else {
                    self.applicationHandleActivity(nil)

                    completionHandler(.noData)
                    
                }
                
            }
            
        }
        else {
            completionHandler(.noData)
            
        }
        
    }
    
    func applicationFetchLatestEvent(completion: @escaping (Events?) -> Void) {
        if let context = AppManager.shared.appStorageContext() {
            let fetch: NSFetchRequest<Events> = Events.fetchRequest()
            fetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            fetch.fetchLimit = 1
            
            do {
                if let existing = try context.fetch(fetch).first {
                    self.applicationHandleActivity(existing)

                    completion(existing)
                    
                }
                else {
                    self.applicationHandleActivity(nil)

                    completion(nil)
                    
                }
                
            }
            catch {
                completion(nil)
                
            }
            
        }
        else {
            completion(nil)
            
        }
        
    }
    
}

