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
            return
        }

        if BluetoothManager.shared.state != .allowed && BluetoothManager.shared.state != .unknown && self.onboardingStep(.bluetooth) == .unseen {
            self.state = .bluetooth
            self.updated = Date()
            return
        }

        if CloudManager.shared.state != .enabled && CloudManager.shared.state != .unknown {
            #if os(macOS)
                if self.onboardingStep(.cloud) == .unseen {
                    self.state = .cloud
                    self.updated = Date()
                    return

                }
            
            #else
                if CloudManager.shared.state == .disabled && self.onboardingStep(.cloud) == .unseen {
                    self.state = .cloud
                    self.updated = Date()
                    return

                }
                else if CloudManager.shared.state == .blocked && self.onboardingStep(.notifications) == .unseen {
                    self.state = .notifications
                    self.updated = Date()
                    return

                }
            
            #endif

        }

        #if os(macOS)
            if ProcessManager.shared.helper.flag == false && self.onboardingStep(.process) == .unseen {
                self.state = .process
                self.updated = Date()
                return

            }
            
            if SettingsManager.shared.enabledAutoLaunch == .undetermined {
                self.state = .loginatlaunch
                self.updated = Date()
                return

            }
            
            if self.onboardingStep(.ios) == .unseen {
                self.state = .ios
                self.updated = Date()
                return

            }

        #elseif os(iOS)
            if self.onboardingStep(.macos) == .unseen {
                self.state = .macos
                self.updated = Date()
                return

            }

        #endif
        
        self.state = .complete
        self.updated = Date()
        
    }
    
    public func onboardingAction(_ type:OnboardingActionType) {
        if state == .intro {
            _ = self.onboardingStep(.intro, insert: true)
            
        }
         
        if state == .bluetooth {
            if type == .primary {
                switch BluetoothManager.shared.state {
                    case .undetermined : BluetoothManager.shared.bluetoothAuthorization(true)
                    case .allowed : BluetoothManager.shared.bluetoothAuthorization(true)
                    default : self.onboardingPermissionsUpdate(.bluetooth)
                    
                }

            }
            else {
                _ = self.onboardingStep(.bluetooth, insert: true)
                self.onboardingSetup()

            }
            
        }
         
        if state == .cloud {
            #if os(macOS)
                if type == .primary {
                    if CloudManager.shared.state == .disabled {
                        self.onboardingPermissionsUpdate(.cloud)
                        
                    }
                    else if CloudManager.shared.state == .blocked {
                        CloudManager.shared.cloudAllowNotifications()
                        
                    }

                }
                else {
                    _ = self.onboardingStep(.cloud, insert: true)
                    self.onboardingSetup()

                }
            
            #elseif os(iOS)
                _ = self.onboardingStep(.cloud, insert: true)
                self.onboardingSetup()

            #endif

        }
        
        #if os(iOS)
            if state == .notifications {
                if type == .primary {
                    switch CloudManager.shared.state {
                        case .blocked : CloudManager.shared.cloudAllowNotifications()
                        case .disabled : self.onboardingPermissionsUpdate(.notifications)
                        default : self.onboardingPermissionsUpdate(.cloud)
                        
                    }

                }
                else {
                    _ = self.onboardingStep(.notifications, insert: true)
                    self.onboardingSetup()

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
                if type == .primary {
                    ProcessManager.shared.processInstallHelper()
                    
                }
                else {
                    _ = self.onboardingStep(.process, insert: true)
                    self.onboardingSetup()

                }
                
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
