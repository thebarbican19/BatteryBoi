//
//  BBOnboardingManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/28/23.
//

import Foundation
import Combine

#if os(macOS)
    import AppKit

#elseif os(iOS)
    import UIKit

#endif

class OnboardingManager:ObservableObject {
    static var shared = OnboardingManager()
    
    @Published var state:OnboardingViewType = .complete
    @Published var updated:Date? = nil
    
    private var updates = Set<AnyCancellable>()

    init() {
        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            if key == .onboardingStep {
                self.onboardingSetup()

            }
            
        }.store(in: &updates)
        
        CloudManager.shared.$state.receive(on: DispatchQueue.main).sink { _ in
            self.onboardingSetup()

        }.store(in: &updates)
        
        BluetoothManager.shared.$state.receive(on: DispatchQueue.main).sink { _ in
            self.onboardingSetup()

        }.store(in: &updates)
        
        #if os(macOS)
//            ProcessManager.shared.$state.receive(on: DispatchQueue.main).sink { _ in
//                self.onboardingSetup()
//
//            }.store(in: &updates)
//        
        #endif
        
        self.onboardingSetup()
        
    }

    public func onboardingSetup() {
        if self.onboardingStep(.intro) == .unseen {
            self.state = .intro
            self.updated = Date()

        }
        else if BluetoothManager.shared.state != .allowed && BluetoothManager.shared.state != .unknown {
            self.state = .bluetooth
            self.updated = Date()

        }
        else if CloudManager.shared.state != .enabled && CloudManager.shared.state != .unknown {
            switch CloudManager.shared.state {
                case .disabled : self.state = .cloud
                case .blocked : self.state = .notifications
                default : break
                
            }
            
            self.updated = Date()

        }
        else if self.onboardingStep(.admin) == .unseen && AppManager.shared.appDeviceType.mac == true {
            self.state = .admin
            self.updated = Date()

        }
        else {
            self.state = .complete
            self.updated = Date()
            
        }
        
    }
    
    public func onboardingAction() {
        if state == .intro {
            _ = self.onboardingStep(.intro, insert: true)
            
        }
        else if state == .bluetooth {
            switch BluetoothManager.shared.state {
                case .undetermined : BluetoothManager.shared.bluetoothAuthorization(true)
                case .allowed : BluetoothManager.shared.bluetoothAuthorization(true)
                default : self.onboardingPermissionsUpdate(.bluetooth)
                
            }
            
        }
        else if state == .cloud {
            if CloudManager.shared.state == .disabled {
                self.onboardingPermissionsUpdate(.cloud)
                
            }

        }
        else if state == .notifications {
            switch CloudManager.shared.state {
                case .blocked : CloudManager.shared.cloudAllowNotifications()
                case .disabled : self.onboardingPermissionsUpdate(.notifications)
                default : self.onboardingPermissionsUpdate(.cloud)

            }
            
        }
        else if state == .admin {
            #if os(macOS)
//                if ProcessManager.shared.state == .allowed {
//                    ProcessManager.shared.processInstallScript()
//                    
//                }
            
            #endif
            
        }
        
    }
    
    private func onboardingPermissionsUpdate(_ step:OnboardingViewType) {
        #if os(macOS)
            var url:URL? = nil
            switch step {
                case .notifications : url = URL(fileURLWithPath: "/System/Library/PreferencePanes/Notifications.prefPane")
                case .bluetooth : url = URL(fileURLWithPath: "/System/Library/PreferencePanes/Bluetooth.prefPane")
                case .cloud : url = URL(string: "x-apple.systempreferences:com.apple.preferences.icloud")
                default : break
                
            }
            
            if let url = url {
                NSWorkspace.shared.open(url)

            }
        
        #elseif os(iOS)
            if step == .cloud {
                
                
            }
            else {
                if let settings = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(settings) {
                        UIApplication.shared.open(settings, options: [:], completionHandler: nil)
                        
                    }
                    
                }
                
            }
        
        #endif

    }
    
    private func onboardingStep(_ step:OnboardingViewType, insert:Bool = false) -> OnboardingStepViewed {
        var list:Array<OnboardingViewType> = []
        
        if let existing = UserDefaults.main.object(forKey: SystemDefaultsKeys.onboardingStep.rawValue) as? [String] {
            list = existing.compactMap({ OnboardingViewType(rawValue: $0) })
            
        }
        
        if insert == true {
            list.append(step)

            UserDefaults.save(.onboardingStep, value: list.compactMap({ $0.rawValue }))

        }
        
        return list.filter({ $0 == step }).isEmpty ? .unseen : .seen

    }
    
}
