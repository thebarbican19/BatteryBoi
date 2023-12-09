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
    @Published var homebrew:ProcessHomebrewState = .unknown

    private var updates = Set<AnyCancellable>()

    init() {
        AppManager.shared.appTimer(18).dropFirst().sink { _ in
            if self.homebrew == .unknown {
                self.processCheckHomebrew()

            }
            
        }.store(in: &updates)

        self.processInstallHelper()
        
    }
    
    public var connection: NSXPCConnection? = {
        if let id = Bundle.main.infoDictionary?["ENV_MACH_ID"] as? String  {
            let connection = NSXPCConnection(machServiceName: id, options: .privileged)
            //connection.remoteObjectInterface = NSXPCInterface(with: HelperToolProtocol.self)
            
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
    
    public func processInbound(_ command:ProcessPrimaryCommands?, subcommand:ProcessSecondaryCommands?, flags:[String] = []) -> String? {
        var output:String = ""
        
        guard let command = command else {
            output.append(self.processHeaderOutput("UNSUPPORTED", state:.error))
            
            for supported in ProcessPrimaryCommands.allCases {
                output.append(self.processValueOutput(supported.description, value: supported.rawValue, reverse:true))
                
            }
            
            return output
            
        }
        
        var secondary = command.secondary.first
        
        if let subcommand = subcommand {
            guard let prompt = command.secondary.first(where: { $0 == subcommand}) else {
                output.append(self.processHeaderOutput("UNSUPPORTED", state:.error))
                
                for supported in command.secondary {
                    output.append(self.processValueOutput(supported.rawValue, value: nil))
                    
                }
                
                return output
                
            }
            
            secondary = prompt
            
        }
        
        if let update = UpdateManager.shared.available {
            output.append(self.processHeaderOutput("UPDATE AVAILABLE", state:.error))

            output.append(self.processValueOutput(update.version.formatted, value:"Please Update to Version to Continue", reverse: true))

        }
        else {
            if command == .menubar {
                if secondary == .info {
                    output.append("\n----------MENUBAR----------\n\n")
                    
                    output.append(self.processValueOutput("Primary Display (-p)", value:MenubarManager.shared.menubarPrimaryDisplay.type))
                    output.append(self.processValueOutput("Secondary Display (-s)", value:MenubarManager.shared.menubarSecondaryDisplay.type))
                    output.append(self.processValueOutput("Menubar Style (-c)", value: MenubarManager.shared.menubarStyle.rawValue))
                    output.append(self.processValueOutput("Pulsating Animation (-a)", value: MenubarManager.shared.menubarPulsingAnimation.string))
                    output.append(self.processValueOutput("Progress Bar Fill (-b)", value: MenubarManager.shared.menubarProgressBar.description))
                    output.append(self.processValueOutput("Icon Radius (-r)", value: "\(MenubarManager.shared.menubarRadius)px"))
                    
                    
                }
                else if secondary == .set {
                    if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                        output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                        
                        output.append(self.processValueOutput("Menubar Primary Display", value: "-p", reverse:true))
                        output.append(self.processValueOutput("Menubar Seconary Display", value: "-s", reverse:true))
                        output.append(self.processValueOutput("Menubar Style", value: "-c", reverse:true))
                        output.append(self.processValueOutput("Animation Toggle", value: "-a", reverse:true))
                        output.append(self.processValueOutput("Progress Bar Fill", value: "-b", reverse:true))
                        output.append(self.processValueOutput("Icon Radius", value: "-r", reverse:true))
                        
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
                                    output.append(self.processValueOutput(supported.type, value: supported.rawValue, reverse:true))
                                    
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
                                    output.append(self.processValueOutput(supported.description, value: supported.rawValue, reverse:true))
                                    
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
                                    output.append(self.processValueOutput("", value: supported.rawValue, reverse:true))
                                    
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
                                output.append(self.processValueOutput("Must be of Type", value: "FLOAT"))
                                
                            }
                            
                        }
                        else {
                            output.append(self.processHeaderOutput("INVALID FLAG", state:.error))
                            
                            output.append(self.processValueOutput("Menubar Primary Display", value: "-p", reverse:true))
                            output.append(self.processValueOutput("Menubar Seconary Display", value: "-s", reverse:true))
                            output.append(self.processValueOutput("Menubar Style", value: "-c", reverse:true))
                            output.append(self.processValueOutput("Animation Toggle", value: "-a", reverse:true))
                            output.append(self.processValueOutput("Progress Bar Fill", value: "-b", reverse:true))
                            output.append(self.processValueOutput("Icon Radius", value: "-r", reverse:true))
                            
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
                    
                    output.append(self.processValueOutput("Charge", value: String(BatteryManager.shared.percentage)))
                    output.append(self.processValueOutput("Charging", value: String(BatteryManager.shared.charging.state.charging ? "Yes":"No")))
                    output.append(self.processValueOutput("Charge To", value: "75%"))
                    
                    if let metrics = BatteryManager.shared.metrics {
                        output.append(self.processValueOutput("Cycle Count", value: metrics.cycles.formatted))
                        
                    }
                    
                    if BatteryManager.shared.charging.state == .charging {
                        output.append(self.processValueOutput("Time Until Fully Charged", value: "32 Minutes"))
                        
                    }
                    else {
                        output.append(self.processValueOutput("Time Until Empty", value: "32 Minutes"))
                        
                    }
                    
                    output.append(self.processValueOutput("Health", value: "Normal"))
                    output.append(self.processValueOutput("Low Power Mode", value: "No"))
                    output.append(self.processValueOutput("Overheating", value: "No"))
                    output.append(self.processValueOutput("Last Charged", value: "6 Hours Ago"))
                    
                }
                else if secondary == .set {
                    //set charge limit
                    //set efficient mode
                    
                }
                
            }
            else if command == .debug {
                if secondary == .info {
                    output.append("\n----------GENERAL----------\n\n")
                    
                    output.append(self.processValueOutput("Installed On", value: AppManager.shared.appInstalled.formatted))
                    output.append(self.processValueOutput("Device", value: AppManager.shared.appDeviceType.name()))
                    output.append(self.processValueOutput("User ID", value: AppManager.shared.appIdentifyer))
                    output.append(self.processValueOutput("Usage Count", value: String(AppManager.shared.appUsage?.day ?? 0)))
                    output.append(self.processValueOutput("Homebrew", value: ProcessManager.shared.homebrew.rawValue))
                    
                    output.append("\n----------ONBOARDING----------\n\n")
                    
                    output.append(self.processValueOutput("State", value: OnboardingManager.shared.state.rawValue))
                    
                    output.append("\n----------ICLOUD----------\n\n")
                    
                    output.append(self.processValueOutput("State", value: CloudManager.shared.state.title))
                    output.append(self.processValueOutput("Syncing", value: CloudManager.shared.syncing.rawValue))
                    output.append(self.processValueOutput("User ID", value: CloudManager.shared.id ?? "PermissionsUnknownLabel".localise()))
                    
                    output.append("\n----------BLUETOOTH----------\n\n")
                    
                    output.append(self.processValueOutput("State", value: BluetoothManager.shared.state.title))
                    output.append(self.processValueOutput("Discoverable Proximity", value: BluetoothManager.shared.proximity.string))
                    
                    output.append("\n----------SETTINGS----------\n\n")
                    
                    output.append(self.processValueOutput("SettingsSoundEffectsLabel".localise(), value: SettingsManager.shared.enabledSoundEffects.subtitle))
                    output.append(self.processValueOutput("SettingsCustomizationThemeTitle".localise(), value: SettingsManager.shared.enabledTheme.name))

                    output.append("\n----------RECENT EVENTS----------\n\n")

                    for event in AppManager.shared.appListEvents(20) {
                        output.append(self.processValueOutput("Notify", value: event.notify))
                        output.append(self.processValueOutput("State", value: event.state))
                        output.append(self.processValueOutput("Charge", value: "\(event.charge)"))

                    }
                    
                }
                
            }
            else if command == .devices {
                if secondary == .list {
                    for device in AppManager.shared.list {
                        output.append("\n----------DEVICE #\(device.order + 1)----------\n\n")
                        
                        output.append(self.processValueOutput("ID", value: device.id))
                        output.append(self.processValueOutput("Name", value: device.name))
                        output.append(self.processValueOutput("Added", value: "\(device.added?.formatted ?? "Unknown")"))
                        output.append(self.processValueOutput("Updated", value: device.polled?.formatted ?? "Never"))
                        output.append(self.processValueOutput("Favourited", value: device.favourite.string))
                        output.append(self.processValueOutput("Events", value: "\(device.events.count)"))
                        
                    }
                    
                }
                else if secondary == .set || secondary == .remove {
                    if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                        output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                        
                        output.append(self.processValueOutput("Device Name", value: "-n", reverse:true))
                        output.append(self.processValueOutput("Device ID", value: "-id", reverse:true))
                        
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
                    
                    output.append(self.processValueOutput("SettingsSoundEffectsLabel".localise(), value: SettingsManager.shared.enabledSoundEffects.subtitle))
                    output.append(self.processValueOutput("SettingsCustomizationThemeTitle".localise(), value: SettingsManager.shared.enabledTheme.name))

                }
                else if secondary == .set {
                    if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                        output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                        
                        output.append(self.processValueOutput("SettingsSoundEffectsLabel".localise(), value: "-m", reverse:true))
                        output.append(self.processValueOutput("SettingsCustomizationThemeTitle".localise(), value: "-a", reverse:true))
                        
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
                                    output.append(self.processValueOutput(supported.name, value: supported.rawValue, reverse:true))
                                    
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
                    output.append(self.processValueOutput("Opening URL", value: url.absoluteString))
                    
                }
                
            }
            else if command == .rate {
                if let url = URL(string: "https://www.producthunt.com/products/batteryboi/reviews") {
                    NSWorkspace.shared.open(url)
                    
                    output.append(self.processHeaderOutput("THANK YOU", state:.sucsess))
                    output.append(self.processValueOutput("Opening URL", value: url.absoluteString))
                    
                }
                
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
    
    private func processCheckHomebrew() {
        if let response = self.processWithArguments("/bin/sh", arguments: ["-c", "brew --version"]) {
            if response.starts(with: "Homebrew") {
                self.homebrew = .installed
                
            }
            
        }
        
        if self.homebrew == .unknown {
            self.homebrew = .notfound
            
        }
        
    }
    
    public func processWithArguments(_ path:String, arguments:[String], whitespace:Bool = false) -> String? {
        let process = Process()
        process.launchPath = path
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe

        process.launch()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            if whitespace == true {
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

            }
            else {
                return String(data: data, encoding: .utf8)

            }
            
        }
            
        return nil
                
    }
    
    private func processHeaderOutput(_ response:String, state:ProcessResponseHeaderType) -> String {
        switch state {
            case .error : return "\n\u{001B}[1m\u{001B}[31m\(response)\u{001B}[0m\n"
            case .sucsess : return  "\n\u{001B}[1m\u{001B}[32m\(response)\u{001B}[0m\n"
            case .normal : return "\n\u{001B}[1m\(response)\u{001B}[0m\n"

        }

    }

    private func processValueOutput(_ label:String, value:String?, reverse:Bool = false) -> String {
        if let value = value {
            switch reverse {
                case true : return " - \u{001B}[1m\(value)\u{001B}[0m: \(label)\n"
                case false : return " - \(label): \u{001B}[1m\(value)\u{001B}[0m\n"
                
            }
           
        }
        else {
            return " - \(label)\n"
            
        }

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
