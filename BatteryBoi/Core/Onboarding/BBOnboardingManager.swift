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

public class OnboardingManager: ObservableObject {
    static var shared = OnboardingManager()

    @Published var state: OnboardingViewType = .complete
    @Published var updated: Date? = nil

    private var updates = Set<AnyCancellable>()

    init() {
        UserDefaults.changed.receive(on: DispatchQueue.main).sink { key in
            if key == .onboardingStep || key == .enabledLogin {
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
            ProcessManager.shared.$interface.receive(on: DispatchQueue.main).sink { state in
                self.onboardingSetup()

            }.store(in: &updates)
        
            ProcessManager.shared.$helper.receive(on: DispatchQueue.main).sink { _ in
                self.onboardingSetup()

            }.store(in: &updates)

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
                self.state = .cloud
            
            #else
                switch CloudManager.shared.state {
                    case .disabled : self.state = .cloud
                    case .blocked : self.state = .notifications
                    default : break
                    
                }
            
            #endif
           
            self.updated = Date()

        }
        else if SystemDeviceTypes.type.mac == true {
            #if os(macOS)
//                if self.onboardingStep(.nobatt) == .unseen && AppManager.shared.appDeviceType.battery == false {
//                    self.state = .nobatt
//                    self.updated = Date()
//
//                }
                if ProcessManager.shared.helper.flag == false {
                    self.state = .process
                    self.updated = Date()
                    
                }
                else if SettingsManager.shared.enabledAutoLaunch == .undetermined {
                    self.state = .loginatlaunch
                    self.updated = Date()
                    
                }
                else if self.onboardingStep(.ios) == .unseen {
                    self.state = .ios
                    self.updated = Date()
                    
                }
                else {
                    self.state = .complete
                    self.updated = Date()
                    
                }
            
            #endif
        }
        else if SystemDeviceTypes.type.mac == false {
            #if os(iOS)
                if self.onboardingStep(.macos) == .unseen {
                    self.state = .macos
                    self.updated = Date()
                    
                }
                else {
                    self.state = .complete
                    self.updated = Date()
                    
                }
            
            #else
                self.state = .complete
                self.updated = Date()
            
            #endif
                        
        }
        
    }
    
    public func onboardingAction(_ type:OnboardingActionType) {
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
            
            if state == .macos {
                _ = self.onboardingStep(.macos, insert: true)

                if let url = URL(string: "https://batteryboi.ovatar.io") {
                    UIApplication.shared.open(url)

                }
                
            }
        
        #endif

        #if os(macOS)
            if state == .loginatlaunch {
                switch type {
                    case .primary : SettingsManager.shared.enabledAutoLaunch = .enabled
                    case .secondary : SettingsManager.shared.enabledAutoLaunch = .disabled
                    
                }
                
            }
            
            if state == .process {
                ProcessManager.shared.processInstallHelper()
                
            }
            
            if state == .ios {
                _ = self.onboardingStep(.ios, insert: true)

                if let url = URL(string: "https://batteryboi.ovatar.io") {
                    NSWorkspace.shared.open(url)

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
