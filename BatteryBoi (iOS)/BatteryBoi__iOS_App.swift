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
            ContentView()
            
        }
        
    }
    
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var shared = AppManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ovatar.batteryapp.refresh", using: nil) { task in
            
//            self.handleAppRefresh(task: task as! BGAppRefreshTask)
            
        }
        
        return true
        
    }
    
//    func handleAppRefresh(task: BGAppRefreshTask) {
//        scheduleAppRefresh() // Schedule the next refresh.
//
//        task.expirationHandler = {
//            // Clean up any unfinished task business by marking where you.
//            // stopped or ending the task outright.
//        }
//
//        // Check for updates from CloudKit
//        checkForUpdatesInCloudKit { (result) in
//            task.setTaskCompleted(success: result == .newData)
//        }
//
//    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
           print("Components" ,components)
            
        }
    
        return true
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error" ,error)
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification {
            //CloudManager.shared.cloudNotification(notification)
            AppManager.shared.polled = Date()
            
            completionHandler(.newData)
            
        }
        else {
            completionHandler(.noData)
            
        }
        
    }
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        print("userinfo" ,userInfo)
//        let attributes = EventsNotifyAttributes(device: "MYDEVICE")
//        let state = EventsNotifyAttributes.ContentState.init(battery: 80, charging: true)
//        let content = ActivityContent(state: state, staleDate: nil)
//
//        let activity = try? Activity.request(attributes: attributes, content: content)
//
//        completionHandler(.newData)
//        
////        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKQueryNotification {
//////            if let recordID = notification.recordID {
//////                print("recordID" ,recordID)
////
////                        
//////                        if record.recordType == "CD_Events" {
//////                            let fetch: NSFetchRequest<Events> = Events.fetchRequest()
//////                            fetch.predicate = NSPredicate(format: "id == %@", recordID)
//////                            
//////                            do {
//////                                let results = try context.fetch(fetch).last
//////
//////                                let charge:Int = Int(results?.charge ?? 69)
//////                                let attributes = EventsNotifyAttributes(device: "MYDEVICE")
//////                                let state = EventsNotifyAttributes.ContentState.init(battery: charge, charging: true)
//////                                let content = ActivityContent(state: state, staleDate: nil)
//////                                
//////                                do {
//////                                    let activity = try Activity.request(attributes: attributes, content: content)
//////                                    
//////                                    print("Battery Activity started for \("Random Deice")")
//////                                    
//////                                }
//////                                catch {
//////                                    print("Failed to start battery activity: \(error)")
//////                                    
//////                                }
//////                                
//////                            }
//////                            catch {
//////                                
//////                                
//////                            }
//////                            
//////                        }
////                                            
////    
////                    
////                    
//////                    }
////            
////            
//////            let charge:Int = Int(results?.charge ?? 69)
////         
////
//////                
//////            }
//////            else {
//////               completionHandler(.noData)
//////                
//////            }
////    
////        }
////        else {
////           completionHandler(.noData)
////           
////       }
//
//   }
        
}

