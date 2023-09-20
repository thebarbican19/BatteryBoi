//
//  BBAppManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/9/23.
//

import Foundation
import EnalogSwift
import Combine
import Sparkle
import SwiftUI

class AppManager:ObservableObject {
    static var shared = AppManager()
    
    @Published var counter = 0
    @Published var device:BluetoothObject? = nil
    @Published var alert:HUDAlertTypes? = nil
    @Published var menu:SystemMenuView = .devices
    @Published var profile:SystemProfileObject? = nil

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
           
        if #available(macOS 13.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if self.appDistribution() == .direct {
                    self.profile = self.appProfile(force: false)
                    
                }
                
            }
            
        }
        
        self.timer?.store(in: &updates)
    
    }
    
    deinit {
        self.timer?.cancel()
        self.updates.forEach { $0.cancel() }
 
    }

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
    
    public var appIdentifyer:String {
        if let id = UserDefaults.main.object(forKey: SystemDefaultsKeys.versionIdenfiyer.rawValue) as? String {
            return id
            
        }
        else {
            let id = "\(Locale.current.regionCode?.uppercased() ?? "US")-\(UUID().uuidString)"
            
            UserDefaults.save(.versionIdenfiyer, value: id)

            return id
            
        }
        
    }
    
    public var appDeviceType:SystemDeviceTypes {
        let platform = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        if let model = IORegistryEntryCreateCFProperty(platform, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            if let type = String(data: model, encoding: .utf8)?.cString(using: .utf8) {
                if String(cString: type).lowercased().contains("macbookpro") { return .macbookPro }
                else if String(cString: type).lowercased().contains("macbookair") { return .macbookAir }
                else if String(cString: type).lowercased().contains("macbook") { return .macbook }
                else if String(cString: type).lowercased().contains("imac") { return .imac }
                else if String(cString: type).lowercased().contains("macmini") { return .macMini }
                else if String(cString: type).lowercased().contains("macstudio") { return .macStudio }
                else if String(cString: type).lowercased().contains("macpro") { return .macPro }
                else { return .unknown }
              
            }
          
        }

        IOObjectRelease(platform)

        return .unknown
      
    }
    
    private func appProfile(force:Bool = false) -> SystemProfileObject? {
        if let payload = UserDefaults.main.object(forKey: SystemDefaultsKeys.profilePayload.rawValue) as? String {

            if let object =  try? JSONDecoder().decode([SystemProfileObject].self, from: Data(payload.utf8)) {
                return object.first
                
            }
            
        }
        else {
            if FileManager.default.fileExists(atPath: "/usr/bin/python3") {
                if let script = Bundle.main.path(forResource: "BBProfileScript", ofType: "py") {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
                    process.arguments = [script]
                    
                    let pipe = Pipe()
                    process.standardOutput = pipe
                    
                    do {
                        try process.run()
                        process.waitUntilExit()
                        
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        
                        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                            
                            UserDefaults.save(.profilePayload, value: output)
                            UserDefaults.save(.profileChecked, value: Date())
                            
                            if let object = try? JSONDecoder().decode([SystemProfileObject].self, from: Data(output.utf8)) {
                                if let id = object.first?.id, let display = object.first?.display {
                                    let first = SystemProfileObject(id: id, display: display)
                                    
                                    if let channel = Bundle.main.infoDictionary?["SD_SLACK_CHANNEL"] as? String  {
                                        EnalogManager.main.ingest(SystemEvents.userProfile, description: "Profile Found: \(display)", metadata: object, channel:.init(.slack, id: channel))
                                        
                                    }
                                    
                                    return first
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    catch {
                        print("Profile Error: ", error)
                        
                    }
                    
                }
                
            }
            
        }
            
        return nil
        
    }
    
    public func appDistribution() -> SystemDistribution {
        let task = Process()
        task.launchPath = "/usr/bin/codesign"
        task.arguments = ["-dv", "--verbose=4", Bundle.main.bundlePath]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.launch()
        task.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: data, encoding: .utf8) {
            if output.contains("Authority=Apple Mac OS Application Signing") {
                return .appstore

            }
            
            
        }
            
        return .direct
            
    }
        
}
