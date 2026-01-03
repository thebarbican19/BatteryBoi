//
//  BBHeartbeatManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 1/3/26.
//

import Foundation
import Combine
import SwiftUI

public enum HeartbeatDeviceType: String, CaseIterable {
    case iphone
    case ipad
    case mac
    case unknown
    
    static func from(_ raw: String) 
        -> HeartbeatDeviceType {
        guard let appType = AppDeviceTypes(rawValue: raw) else { 
            return 
                .unknown 
        }
        
        if appType.mac { 
            return 
                .mac 
        }
        
        if appType == .iphone { 
            return 
                .iphone 
        }
        
        if appType == .ipad { 
            return 
                .ipad 
        }
        
        return 
            .unknown
    }
}

public struct HeartbeatObject: Identifiable {
    public var id: String
    public var type: String
    public var name: String
    public var timestamp: TimeInterval
    public var os: String
    
    public var deviceType: HeartbeatDeviceType {
        return 
            HeartbeatDeviceType.from(type)
    }
}

public class HeartbeatManager: ObservableObject {
    public static let shared = HeartbeatManager()
    
    @Published public var activeDevices: [HeartbeatObject] = []
    
    private var updates = Set<AnyCancellable>()
    
    init() {
        self.heartbeatSetupObserver()
        self.heartbeatStart()
    }
    
    private func heartbeatSetupObserver() {
        // Observer changes in AppManager's device list (Synced via CloudKit/SwiftData)
        AppManager.shared.$devices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.heartbeatRefreshActiveDevices(devices)
            }
            .store(in: &updates)
    }
    
    public func heartbeatStart() {
        // Ensure local device presence is recorded immediately
        self.heartbeatBroadcast()
        
        // Broadcast every 5 minutes to keep device active
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.heartbeatBroadcast()
            }
            .store(in: &updates)
    }
    
    private func heartbeatBroadcast() {
        // Leverages the existing robust CloudKit sync in AppManager
        AppManager.shared.appStoreDevice()
    }
    
    public func heartbeatRefreshActiveDevices(_ devices: [AppDeviceObject]? = nil) {
        let source = devices ?? AppManager.shared.devices
        let now = Date().timeIntervalSince1970
        let threshold: TimeInterval = 3600 * 24 // 24 hours
        
        let mapped: [HeartbeatObject] = source.compactMap { device in
            // Filter for devices seen recently
            if let refreshed = device.refreshed?.timeIntervalSince1970,
               now - refreshed < threshold {
                
                return HeartbeatObject(
                    id: device.id.uuidString,
                    type: device.profile.subtype ?? "unknown",
                    name: device.name,
                    timestamp: refreshed,
                    os: device.object?.os ?? "unknown"
                )
            }
            return nil
        }
        
        self.activeDevices = mapped
    }
    
    public func heartbeat(_ type: HeartbeatDeviceType? = nil) 
        -> [HeartbeatObject] {
        if let type = type {
            return 
                self.activeDevices.filter { $0.deviceType == type }
        }
        
        return 
            self.activeDevices
    }
    
    public func heartbeatCheckHasIPhone() 
        -> Bool {
        return 
            self.heartbeat(.iphone).isEmpty == false
    }
    
    public func heartbeatCheckHasMac() 
        -> Bool {
        return 
            self.heartbeat(.mac).isEmpty == false
    }
}