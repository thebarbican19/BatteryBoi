//
//  BBProcessManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/26/23.
//

import Foundation
import EnalogSwift
import Combine
import AppKit
import SecurityFoundation
import ServiceManagement

class ProcessManager:ObservableObject {
    static var shared = ProcessManager()
    
    @Published var interface:ProcessPermissionState = .unknown
    @Published var helper:ProcessPermissionState = .unknown

    private var updates = Set<AnyCancellable>()
    
    public var connection: NSXPCConnection? = {
        if let id = Bundle.main.infoDictionary?["ENV_MACH_ID"] as? String  {
            print("!Mach Setup " ,id)
            let connection = NSXPCConnection(machServiceName: id, options: .privileged)
            connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
            connection.resume()
            
            return connection
            
        }
        
        return nil
        
    }()
    
    public func processInstallInterface() {
        #if MAINTARGET
            if ToolInstaller.install() == true {
                DispatchQueue.main.async {
                    self.interface = .allowed
                    
                }

            }
            else {
                DispatchQueue.main.async {
                    self.interface = .denied
                    
                }
                
            }
        
        #endif
        
    }
    
    public func processInstallHelper() {
        var reference: AuthorizationRef?
        var error: Unmanaged<CFError>?

        let helper = "helperboi" as CFString
        let flags: AuthorizationFlags = [.interactionAllowed, .preAuthorize, .extendRights]

        var item = kSMRightBlessPrivilegedHelper.withCString {
            AuthorizationItem(name: $0, valueLength: 0, value: nil, flags: 0)
            
        }
        
        var rights = withUnsafeMutablePointer(to: &item) {
            AuthorizationRights(count: 1, items: $0)
            
        }

        AuthorizationCreate(&rights, nil, flags, &reference)
        SMJobBless(kSMDomainSystemLaunchd, helper, reference, &error)
        
        if let code = error?.takeRetainedValue() {
            DispatchQueue.main.async {
                switch CFErrorGetCode(code) {
                    case -60005:self.helper = .denied
                    case -60006:self.helper = .denied
                    case -60008:self.helper = .denied
                    default:self.helper = .error
                    
                }
                
            }
            
        }
        else {
            DispatchQueue.main.async {
                self.helper = .allowed
                
            }
                        
        }
        
    }
    
    public func processHelperContext() -> HelperProtocol? {
        if let helper = self.connection?.remoteObjectProxy as? HelperProtocol {
            return helper
            
        }
        else {
            if self.helper == .allowed {
                self.processInstallHelper()

            }
            
            return nil
            
        }
        
    }
    
    public func processInbound(_ command:ProcessPrimaryCommands?, subcommand:ProcessSecondaryCommands?, flags:[String] = []) -> String? {
        var output:String = ""
        
        guard let command = command else {
            output.append(self.processHeaderOutput("UNSUPPORTED", state:.error))
            
            for supported in ProcessPrimaryCommands.allCases {
                output.append(self.processValueOutput(supported.description, value: .init(supported.rawValue), reverse:true))
                
            }
            
            return output
            
        }
        
        var secondary = command.secondary.first
        
        if let subcommand = subcommand {
            guard let prompt = command.secondary.first(where: { $0 == subcommand}) else {
                output.append(self.processHeaderOutput("UNSUPPORTED", state:.error))
                
                for supported in command.secondary {
                    output.append(self.processValueOutput(supported.rawValue, value: .init(nil)))
                    
                }
                
                return output
                
            }
            
            secondary = prompt
            
        }
        
       
        if command == .menubar {
            if secondary == .info {
                output.append("\n----------MENUBAR----------\n\n")
                
                output.append(self.processValueOutput("Primary Display (-p)", value:.init(MenubarManager.shared.menubarPrimaryDisplay.type)))
                output.append(self.processValueOutput("Secondary Display (-s)", value:.init(MenubarManager.shared.menubarSecondaryDisplay.type)))
                output.append(self.processValueOutput("Menubar Style (-c)", value: .init(MenubarManager.shared.menubarStyle.rawValue)))
                output.append(self.processValueOutput("Menubar Colour Scheme (-m)", value: .init(MenubarManager.shared.menubarSchemeType.rawValue)))
                output.append(self.processValueOutput("Pulsating Animation (-a)", value:.init( MenubarManager.shared.menubarPulsingAnimation.string(.enabled))))
                output.append(self.processValueOutput("Progress Bar Fill (-b)", value:.init( MenubarManager.shared.menubarProgressBar.description)))
                output.append(self.processValueOutput("Icon Radius (-r)", value:.init( "\(MenubarManager.shared.menubarRadius)px")))
                
                
            }
            else if secondary == .set {
                if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                    output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                    
                    output.append(self.processValueOutput("Menubar Primary Display", value: .init("-p"), reverse:true))
                    output.append(self.processValueOutput("Menubar Seconary Display", value: .init("-s"), reverse:true))
                    output.append(self.processValueOutput("Menubar Style", value: .init("-c"), reverse:true))
                    output.append(self.processValueOutput("Menubar Colour Scheme", value: .init("-m"), reverse:true))
                    output.append(self.processValueOutput("Animation Toggle", value: .init("-a"), reverse:true))
                    output.append(self.processValueOutput("Progress Bar Fill", value: .init("-b"), reverse:true))
                    output.append(self.processValueOutput("Icon Radius", value: .init("-r"), reverse:true))
                    
                }
                else {
                    if flags[1] == "-s" || flags[1] == "-p" {
                        if let value = MenubarDisplayType(rawValue: flags[2]) {
                            switch flags[1] {
                                case "-p" : MenubarManager.shared.menubarPrimaryDisplay = value
                                case "-s" : MenubarManager.shared.menubarSecondaryDisplay = value
                                default : break
                                
                            }
                            
                            output.append(self.processHeaderOutput("SAVED", state:.sucsess))
                            
                        }
                        else {
                            output.append(self.processHeaderOutput("INVALID VALUE", state:.error))
                            
                            for supported in MenubarDisplayType.allCases {
                                output.append(self.processValueOutput(supported.type, value: .init(supported.rawValue), reverse:true))
                                
                            }
                            
                        }
                        
                    }
                    else if flags[1] == "-a"  {
                        MenubarManager.shared.menubarPulsingAnimation = flags[2].boolean
                        
                        output.append(self.processHeaderOutput("SAVED", state:.sucsess))
                        
                    }
                    else if flags[1] == "-b" {
                        if let value = MenubarProgressType(rawValue: flags[2]) {
                            MenubarManager.shared.menubarProgressBar = value
                            
                            output.append(self.processHeaderOutput("SAVED", state:.sucsess))
                            
                        }
                        else {
                            output.append(self.processHeaderOutput("INVALID VALUE", state:.error))
                            
                            for supported in MenubarProgressType.allCases {
                                output.append(self.processValueOutput(supported.description, value: .init(supported.rawValue), reverse:true))
                                
                            }
                            
                        }
                        
                    }
                    else if flags[1] == "-c" {
                        if let value = MenubarStyle(rawValue: flags[2]) {
                            MenubarManager.shared.menubarStyle = value
                            
                            output.append(self.processHeaderOutput("SAVED", state:.sucsess))
                            
                        }
                        else {
                            output.append(self.processHeaderOutput("INVALID VALUE", state:.error))
                            
                            for supported in MenubarStyle.allCases {
                                output.append(self.processValueOutput("", value: .init(supported.rawValue), reverse:true))
                                
                            }
                            
                        }
                        
                    }
                    else if flags[1] == "-r" {
                        if let value = Float(flags[2]) {
                            MenubarManager.shared.menubarRadius = value
                            
                            output.append(self.processHeaderOutput("SAVED", state:.sucsess))
                            
                        }
                        else {
                            output.append(self.processHeaderOutput("INVALID VALUE", state:.error))
                            output.append(self.processValueOutput("Must be of Type", value:.init( "FLOAT")))
                            
                        }
                        
                    }
                    else if flags[1] == "-m" {
                        if MenubarManager.shared.menubarStyle == .transparent {
                            if let value = MenubarScheme(rawValue: flags[2]) {
                                MenubarManager.shared.menubarSchemeType = value
                                
                                output.append(self.processHeaderOutput("SAVED", state:.sucsess))
                                
                            }
                            else {
                                output.append(self.processHeaderOutput("INVALID VALUE", state:.error))
                                
                                for supported in MenubarScheme.allCases {
                                    output.append(self.processValueOutput("", value: .init(supported.rawValue), reverse:true))
                                    
                                }
                                
                            }
                            
                        }
                        else {
                            output.append(self.processHeaderOutput("ONLY AVAILABLE FOR '\("transparent")' STYLE", state:.error))

                        }
                        
                    }
                    else {
                        output.append(self.processHeaderOutput("INVALID FLAG", state:.error))
                        
                        output.append(self.processValueOutput("Menubar Primary Display", value: .init("-p"), reverse:true))
                        output.append(self.processValueOutput("Menubar Seconary Display", value: .init("-s"), reverse:true))
                        output.append(self.processValueOutput("Menubar Style", value: .init("-c"), reverse:true))
                        output.append(self.processValueOutput("Menubar Colour Scheme", value: .init("-m"), reverse:true))
                        output.append(self.processValueOutput("Animation Toggle", value: .init("-a"), reverse:true))
                        output.append(self.processValueOutput("Progress Bar Fill", value: .init("-b"), reverse:true))
                        output.append(self.processValueOutput("Icon Radius", value: .init("-r"), reverse:true))
                        
                    }
                    
                }
                
            }
            else if secondary == .reset {
                MenubarManager.shared.menubarReset()
                
                output.append(self.processHeaderOutput("RESET TO DEFAULT", state:.sucsess))
                
            }
            
        }
        else if command == .battery {
            if secondary == .info {
                output.append("\n----------GENERAL----------\n\n")
                
                if BatteryManager.shared.charging == .battery {
                    if BatteryManager.shared.percentage <= 25 {
                        output.append(self.processValueOutput("Charge", value:.init( "\(BatteryManager.shared.percentage)%", type:.warning)))

                    }
                    else if BatteryManager.shared.percentage <= 18 {
                        output.append(self.processValueOutput("Charge", value:.init( "\(BatteryManager.shared.percentage)%", type:.error)))

                    }
                    else {
                        output.append(self.processValueOutput("Charge", value:.init( "\(BatteryManager.shared.percentage)%", type:.normal)))

                    }
                    
                    output.append(self.processValueOutput("Charging", value:.init( false.string(.yes))))

                }
                else {
                    output.append(self.processValueOutput("Charge", value:.init( "\(BatteryManager.shared.percentage)%", type:.normal)))
                    output.append(self.processValueOutput("Charging", value:.init( true.string(.yes), type: .sucsess)))

                }
                
                output.append(self.processValueOutput("Charge To", value: .init("100%")))
                output.append(self.processValueOutput("Low Power Mode", value:.init( BatteryManager.shared.mode.flag.string(.enabled), type: BatteryManager.shared.mode.flag ? .sucsess : .normal)))

                if BatteryManager.shared.charging == .charging {
                    output.append(self.processValueOutput("Time Until Fully Charged", value:.init( "32 Minutes")))
                    
                }
                else {
                    output.append(self.processValueOutput("Time Until Empty", value: .init("32 Minutes")))
                    
                }
                
                output.append("\n----------HEALTH----------\n\n")

                if let heath = BatteryManager.shared.health {
                    output.append(self.processValueOutput("Health", value:.init( heath.state.rawValue, type: heath.state.warning)))
                    output.append(self.processValueOutput("Cycle Count", value:.init( "\(heath.cycles)")))
                    output.append(self.processValueOutput("Capacity", value:.init( "\(Int(heath.percentage))%")))

                }
                
                output.append("\n----------TEMPRATURE----------\n\n")

                output.append(self.processValueOutput("Overheating", value: .init(BatteryManager.shared.temperature.state.flag.string(.yes), type: BatteryManager.shared.temperature.state.warning)))
                output.append(self.processValueOutput("Battery Temprature", value: .init(BatteryManager.shared.temperature.formatted)))
                
                
                output.append("\n----------OTHER----------\n\n")

                if let info = BatteryManager.shared.info {
                    output.append(self.processValueOutput("Battery Manufacturer", value: .init(info.manufacturer)))
                    output.append(self.processValueOutput("Serial Number", value: .init(info.serial)))

                    if let accumulated = info.accumulated {
                        output.append(self.processValueOutput("Accumulated Usage", value: .init("\(accumulated) kWh")))

                    }
                    
                }
                
            }
            else if secondary == .set {
                if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                    output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                    
                    output.append(self.processValueOutput("Low Power Mode", value: .init("-m"), reverse:true))
                    
                }
                else {
                    if flags[1] == "-m" {
                        if let value = BatteryModeType(rawValue: flags[2]) {
                            BatteryManager.shared.powerEfficiencyMode(value)
                            
                            output.append(self.processHeaderOutput("SAVED", state:.sucsess))
                            
                        }
                        else {
                            output.append(self.processHeaderOutput("INVALID VALUE", state:.error))
                            
                            for supported in BatteryModeType.allCases.filter({ $0 != .unavailable }) {
                                output.append(self.processValueOutput("", value: .init(supported.rawValue), reverse:true))
                                
                            }
                            
                        }
                        
                    }
                    else {
                        output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                        
                        output.append(self.processValueOutput("Low Power Mode", value: .init("-m"), reverse:true))
                        
                    }
                    
                }
                
            }
            
        }
        else if command == .debug {
            if secondary == .info {
                output.append("\n----------GENERAL----------\n\n")
                
                output.append(self.processValueOutput("Installed On", value:.init( AppManager.shared.appInstalled.formatted)))
                output.append(self.processValueOutput("Device", value:.init( AppManager.shared.appDeviceType.name())))
                output.append(self.processValueOutput("User ID", value: .init(AppManager.shared.appIdentifyer)))
                output.append(self.processValueOutput("Usage Count", value: .init(String(AppManager.shared.appUsage?.day ?? 0))))
                
                output.append("\n----------ONBOARDING----------\n\n")
                
                output.append(self.processValueOutput("State", value: .init(OnboardingManager.shared.state.rawValue)))
                
                output.append("\n----------ICLOUD----------\n\n")
                
                output.append(self.processValueOutput("State", value: .init(CloudManager.shared.state.title)))
                output.append(self.processValueOutput("Syncing", value: .init(CloudManager.shared.syncing.rawValue)))
                output.append(self.processValueOutput("User ID", value:.init( CloudManager.shared.id ?? "PermissionsUnknownLabel".localise())))
                
                output.append("\n----------BLUETOOTH----------\n\n")
                
                output.append(self.processValueOutput("State", value: .init(BluetoothManager.shared.state.title)))
                output.append(self.processValueOutput("Discoverable Proximity", value:.init( BluetoothManager.shared.proximity.string)))
                
                output.append("\n----------SETTINGS----------\n\n")
                
                output.append(self.processValueOutput("SettingsSoundEffectsLabel".localise(), value: .init(SettingsManager.shared.enabledSoundEffects.subtitle)))
                output.append(self.processValueOutput("SettingsCustomizationThemeTitle".localise(), value: .init(SettingsManager.shared.enabledTheme.name)))

                output.append("\n----------RECENT EVENTS----------\n\n")

                for event in AppManager.shared.appListEvents(20) {
                    output.append(self.processValueOutput("Notify", value: .init(event.notify)))
                    output.append(self.processValueOutput("State", value: .init(event.state)))
                    output.append(self.processValueOutput("Charge", value: .init("\(event.charge)")))

                }
                
            }
            
        }
        else if command == .devices {
            if secondary == .list {
                for device in AppManager.shared.list {
                    output.append("\n----------DEVICE #\(device.order + 1)----------\n\n")
                    
                    output.append(self.processValueOutput("ID", value:.init(device.id)))
                    output.append(self.processValueOutput("Name", value: .init(device.name)))
                    output.append(self.processValueOutput("Added", value:.init( "\(device.added?.formatted ?? "Unknown")")))
                    output.append(self.processValueOutput("Updated", value:.init( device.polled?.formatted ?? "Never")))
                    output.append(self.processValueOutput("Favourited", value: .init(device.favourite.string(.yes))))
                    output.append(self.processValueOutput("Events", value: .init("\(device.events.count)")))
                    
                }
                
            }
            else if secondary == .set || secondary == .remove {
                if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                    output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                    
                    output.append(self.processValueOutput("Device Name", value: .init("-n"), reverse:true))
                    output.append(self.processValueOutput("Device ID", value: .init("-id"), reverse:true))
                    
                }
                else {
                    var device:SystemDeviceObject? = nil
                    var response:String = ""
                    
                    if flags[1] == "-n"  {
                        device = AppManager.shared.list.first(where: { $0.name == flags[2] })
                        
                        
                    }
                    else if flags[1] == "-id"  {
                        device = AppManager.shared.list.first(where: { $0.id == flags[2] })
                        
                    }
                    
                    if let device = device {
                        switch secondary {
                            case .set : response = MenubarManager.shared.menubarAppendDevices(device, state: .add)
                            case .remove : response = MenubarManager.shared.menubarAppendDevices(device, state: .remove)
                            default : break
                            
                        }
                        
                        output.append(response)
                        
                    }
                    else {
                        output.append(self.processHeaderOutput("DEVICE NOT FOUND", state:.error))
                        
                    }
                    
                }
                
            }
            else if secondary == .reset {
                AppManager.shared.appDestoryEntity(.devices)
                
                output.append(self.processHeaderOutput("REMOVED ALL DEVICE", state:.sucsess))
                
            }
            
        }
        else if command == .settings {
            if secondary == .info {
                output.append("\n----------SETTINGS----------\n\n")
                
                output.append(self.processValueOutput("SettingsSoundEffectsLabel".localise(), value:.init(SettingsManager.shared.enabledSoundEffects.subtitle)))
                output.append(self.processValueOutput("SettingsCustomizationThemeTitle".localise(), value: .init(SettingsManager.shared.enabledTheme.name)))

            }
            else if secondary == .set {
                if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                    output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                    
                    output.append(self.processValueOutput("SettingsSoundEffectsLabel".localise(), value: .init("-m"), reverse:true))
                    output.append(self.processValueOutput("SettingsCustomizationThemeTitle".localise(), value: .init("-a"), reverse:true))
                    
                }
                else {
                    if flags[1] == "-m" {
                        switch flags[2].boolean {
                            case true : SettingsManager.shared.enabledSoundEffects = .enabled
                            case false : SettingsManager.shared.enabledSoundEffects = .disabled

                        }
                        
                        output.append(self.processHeaderOutput("SAVED", state:.sucsess))

                    }
                    else if flags[1] == "-a" {
                        if let value = SettingsTheme(rawValue: flags[2]) {
                            SettingsManager.shared.enabledTheme = value
                            
                            output.append(self.processHeaderOutput("SAVED", state:.sucsess))
                            
                        }
                        else {
                            output.append(self.processHeaderOutput("INVALID VALUE", state:.error))
                            
                            for supported in SettingsTheme.allCases {
                                output.append(self.processValueOutput(supported.name, value: .init(supported.rawValue), reverse:true))
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            else if secondary == .reset {
                SettingsManager.shared.settingsReset()

                output.append(self.processHeaderOutput("RESET TO DEFAULT", state:.sucsess))

            }
                
        }
        else if command == .website {
            if let url = URL(string: "http://batteryboi.ovatar.io/index?ref=cliboi") {
                NSWorkspace.shared.open(url)
                
                output.append(self.processHeaderOutput("SUCSESS", state:.sucsess))
                output.append(self.processValueOutput("Opening URL", value: .init(url.absoluteString)))
                
            }
            
        }
        else if command == .rate {
            if let url = URL(string: "https://www.producthunt.com/products/batteryboi/reviews?ref=cliboi") {
                NSWorkspace.shared.open(url)
                
                output.append(self.processHeaderOutput("THANK YOU", state:.sucsess))
                output.append(self.processValueOutput("Opening URL", value: .init(url.absoluteString)))
                
            }
            
        }

        
        if output.isEmpty {
            return nil
            
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            output.append("\n\n")
            output.append("\u{001B}[90mBatteryBoi (Open-Source) 2024 Version \(version)\u{001B}[0m")
            output.append("\n\u{001B}[90mPlease Consider Rating BatteryBoi on Product Hunt \u{001B}[1m[cliboi rate]\u{001B}[0m \u{001B}[0m")
            output.append("\n")
            
        }
        
        return output
        
    }
    
    private func processHeaderOutput(_ response:String, state:ProcessResponseHeaderType) -> String {
        switch state {
            case .error:return "\n\u{001B}[1;31m\(response)\u{001B}[0m\n"
            case .sucsess:return "\n\u{001B}[1;32m\(response)\u{001B}[0m\n"
            case .normal:return "\n\u{001B}[1m\(response)\u{001B}[0m\n"
            case .warning:return "\n\u{001B}[1;33m\(response)\u{001B}[0m\n"
            
        }

    }

    private func processValueOutput(_ label:String, value:ProcessResponseValueObjectType, reverse:Bool = false) -> String {
        if reverse == true {
            switch value.type {
                case .error:return " - \u{001B}[1;31m\(value.value)\u{001B}[0m\n"
                case .sucsess:return " - \u{001B}[1;32m\(value.value)\u{001B}[0m\n"
                case .normal:return " - \u{001B}[1m\(value.value)\u{001B}[0m\n"
                case .warning: return " - \u{001B}[1;33m\(value.value)\u{001B}[0m\n"
            }
            
        }
        else {
            switch value.type {
                case .error:return " - \(label): \u{001B}[1;31m\(value.value)\u{001B}[0m\n"
                case .sucsess:return " - \(label): \u{001B}[1;32m\(value.value)\u{001B}[0m\n"
                case .normal:return " - \(label): \u{001B}[1m\(value.value)\u{001B}[0m\n"
                case .warning:return " - \(label): \u{001B}[1;33m\(value.value)\u{001B}[0m\n"
          
            }
            
        }

    }
    
    private func processHomebrewScript(_ file:String) -> String? {
        let path = "/bin/bash"
        let home = NSHomeDirectory()
        let file = file.replacingOccurrences(of: " ", with: "\\ ")
        let command = "\(path) -c 'export HOME=\(home) && \(file)'"
        let script = "do shell script \"\(command.replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print(error)
                
            }
            
        }
        
        return nil
        
    }
    
    private func processRestart(){
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        
        exit(0)
        
    }
    
}
