//
//  DAppManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/9/23.
//

import Foundation
import EnalogSwift
import Combine
import Sparkle

class AppManager:ObservableObject {
    static var shared = AppManager()
    
    @Published var counter = 0
    @Published var device:BluetoothObject? = nil
    @Published var alert:ModalAlertTypes? = nil

    private var updates = Set<AnyCancellable>()
    private var timer: AnyCancellable?

    init() {
        self.timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            
            guard let self = self else {
                return
                
            }
            
            if self.counter > 999 {
                self.counter = 0

            }
            
            self.counter += 1
            
        }
        
        self.timer?.store(in: &updates)
    
    }
    
    deinit {
        self.timer?.cancel()
        self.updates.forEach { $0.cancel() }
 
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
        
}
