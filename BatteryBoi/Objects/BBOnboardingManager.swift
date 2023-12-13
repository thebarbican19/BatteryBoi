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
//            ProcessManager.shared.$interface.receive(on: DispatchQueue.main).sink { _ in
//                self.onboardingSetup()
//
//            }.store(in: &updates)
//        
//            ProcessManager.shared.$helper.receive(on: DispatchQueue.main).sink { _ in
//                self.onboardingSetup()
//
//            }.store(in: &updates)
        
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
            #if os(macOS)
                switch CloudManager.shared.state {
                    case .disabled : self.state = .cloud
                    default : break
                    
                }
            
            #else
                switch CloudManager.shared.state {
                    case .disabled : self.state = .cloud
                    case .blocked : self.state = .notifications
                    default : break
                    
                }
            
            #endif
            
            self.updated = Date()

        }
        else if AppManager.shared.appDeviceType.mac == true {
            #if os(macOS)
//                if self.onboardingStep(.nobatt) == .unseen && AppManager.shared.appDeviceType.battery == false {
//                    self.state = .nobatt
//                    self.updated = Date()
//
//                }
                if self.onboardingStep(.admin) == .unseen {
                    self.state = .admin
                    self.updated = Date()

                }
                else if self.onboardingStep(.cli) == .unseen {
                    self.state = .cli
                    self.updated = Date()
                    
                }
                else {
                    self.state = .complete
                    self.updated = Date()
                    
                }
            
            #endif
        }
        else if AppManager.shared.appDeviceType.mac == false {
            self.state = .complete
            self.updated = Date()
                        
        }
        
    }
    
    public func onboardingAction() {
        if state == .intro {
            _ = self.onboardingStep(.intro, insert: true)
            
        }
         
        if state == .bluetooth {
            switch BluetoothManager.shared.state {
                case .undetermined : BluetoothManager.shared.bluetoothAuthorization(true)
                case .allowed : BluetoothManager.shared.bluetoothAuthorization(true)
                default : self.onboardingPermissionsUpdate(.bluetooth)
                
            }
            
        }
         
        if state == .cloud {
            if CloudManager.shared.state == .disabled {
                self.onboardingPermissionsUpdate(.cloud)
                
            }

        }
        
        #if os(iOS)
            if state == .notifications {
                switch CloudManager.shared.state {
                    case .blocked : CloudManager.shared.cloudAllowNotifications()
                    case .disabled : self.onboardingPermissionsUpdate(.notifications)
                    default : self.onboardingPermissionsUpdate(.cloud)

                }
                
            }
        
        #endif
         
        #if os(macOS)
            if state == .cli {
                _ = self.onboardingStep(.cli, insert: true)
                
            }
        
        #endif

        #if os(macOS)
            if state == .admin {
                if ProcessManager.shared.interface == .unknown {
                    ProcessManager.shared.processInstallInterface()
                    
                }
                
            }
            
        #endif
        
    }
    
    private func onboardingPermissionsUpdate(_ step:OnboardingViewType) {
        #if os(macOS)
            var url:URL? = nil
            switch step {
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
