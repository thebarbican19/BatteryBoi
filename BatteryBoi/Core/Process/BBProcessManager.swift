//
//  BBProcessManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/26/23.
//

import Foundation
import Combine
import AppKit
import SecurityFoundation
import ServiceManagement

public class ProcessManager: ObservableObject {
    static var shared = ProcessManager()

    @Published var interface: ProcessPermissionState = .unknown
    @Published var helper: ProcessPermissionState = .unknown

    private var updates = Set<AnyCancellable>()
    
    init() {
        $helper.delay(for: .seconds(0.8), scheduler: RunLoop.main).receive(on: DispatchQueue.main).sink { state in
            if state == .allowed {
                if let helper = self.processHelperContext() {
                    helper.helperInterfaceState { state in
                        DispatchQueue.main.async {
                            if self.interface == .unknown {
                                switch state {
                                    case .missing : self.interface = .undetermined
                                    case .installed : self.interface = .allowed
                                    
                                }
                                
                            }
                            
                        }
                        
                        if self.interface == .undetermined {
                            self.processInstallInterface()
                            
                        }
                                               
                    }
                    
                }
                
            }
                        
        }.store(in: &updates)
        
    }
    
    public var connection: NSXPCConnection? = {
        if let id = Bundle.main.infoDictionary?["ENV_MACH_ID"] as? String  {
            let connection = NSXPCConnection(machServiceName: id, options: .privileged)
            connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
            connection.resume()
            
            return connection
            
        }
        
        return nil
        
    }()
    
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
                self.interface = .unknown
                
            }
            
        }
        
    }
    
    private func processInstallInterface() {
        if AppManager.shared.distribution == .direct {
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
        else {
            self.interface = .denied

        }
        
    }
    
    public func processHelperContext() -> HelperProtocol? {
        if let helper = self.connection?.remoteObjectProxy as? HelperProtocol {
            helper.setupHomeDirectory(home: FileManager.default.homeDirectoryForCurrentUser)

            if let bundle = Bundle.main.resourcePath {
                if let resorces = try? FileManager.default.contentsOfDirectory(atPath: bundle) {
                    for script in resorces.filter({ $0.hasSuffix(".sh") }) {
                        helper.setupExecutables( "\(Bundle.main.bundleURL)Contents/Resources/\(script)")

                    }
                                        
                }

            }
            
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
                output.append("\n----------COMMANDS----------\n\n")

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
        else if command == .notifications {
            if secondary == .info {
                output.append("\n----------AT PERCENTAGE----------\n\n")
                
                for alert in AlertManager.shared.alerts.filter({ $0.percentage != nil }) {
                    if let percent = alert.percentage {
                        output.append(self.processValueOutput("\(alert.type.rawValue)", value:.init("At \(percent)%")))
                        
                    }
                    
                }
                
                output.append("\n----------OTHER----------\n\n")

                for alert in AlertManager.shared.alerts.filter({ $0.percentage == nil }) {
                    output.append(self.processValueOutput(alert.type.description, value:.init("\(alert.type.rawValue)"), reverse: true))

                }
                
            }
            else if secondary == .reset {
                AlertManager.shared.alertReset()
                
                output.append(self.processHeaderOutput("RESET TO DEFAULT", state:.sucsess))
                
                
            }
            else {
                output.append(self.processHeaderOutput("NOT AVAILABLE IN THIS VERSION", state:.warning))

            }
            
        }
        else if command == .battery {
            if secondary == .info {
                BatteryManager.shared.powerForceRefresh()
                
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
                
                output.append(self.processValueOutput("Low Power Mode", value:.init( BatteryManager.shared.mode.flag.string(.enabled), type: BatteryManager.shared.mode.flag ? .sucsess : .normal)))
                output.append(self.processValueOutput("Charge To", value: .init("\(BatteryManager.shared.max)%")))
   
                if let powered = BatteryManager.shared.info?.powered {
                    output.append(self.processValueOutput("Connected to Power", value:.init( powered.string(.enabled), type:.normal)))
                    
                }

                if BatteryManager.shared.charging == .charging {
                    output.append(self.processValueOutput("Time Until Fully Charged", value:.init( "32 Minutes")))
                    
                }
                else {
                    output.append(self.processValueOutput("Time Until Empty", value: .init("32 Minutes")))
                    
                }
                
                if let watts = BatteryManager.shared.info?.watts {
                    output.append(self.processValueOutput("Watts", value:.init( "\(watts) mAh")))

                }

                output.append("\n----------HEALTH----------\n\n")
                
                if let heath = BatteryManager.shared.health {
                    output.append(self.processValueOutput("Health", value:.init( heath.state.rawValue, type: heath.state.warning)))
                    output.append(self.processValueOutput("Cycle Count", value:.init( "\(heath.cycles)")))
                    output.append(self.processValueOutput("Capacity", value:.init( "\(Int(heath.percentage))%")))
                    output.append(self.processValueOutput("Original Capacity", value:.init( "\(Int(heath.capacity)) mAh")))
                    output.append(self.processValueOutput("Current Capacity", value:.init( "\(Int(heath.available)) mAh")))

                }
                
                output.append("\n----------TEMPRATURE----------\n\n")
                
                output.append(self.processValueOutput("Overheating", value: .init(BatteryManager.shared.thermal.state.flag.string(.yes), type: BatteryManager.shared.thermal.state.warning)))
                output.append(self.processValueOutput("Battery Temprature", value: .init(BatteryManager.shared.thermal.formatted)))
                
                output.append("\n----------OTHER----------\n\n")
                
                if let info = BatteryManager.shared.info {
                    output.append(self.processValueOutput("Battery Manufacturer", value: .init(info.manufacturer)))
                    output.append(self.processValueOutput("Serial Number", value: .init(info.serial)))
                    output.append(self.processValueOutput("Total Batteries", value: .init("\(info.batteries ?? 1)")))

                    if let accumulated = info.accumulated {
                        output.append(self.processValueOutput("Accumulated Usage", value: .init("\(accumulated) kWh")))
                        
                    }
                        
                }
                
            }
            else if secondary == .set {
                if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                    output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                    
                    output.append(self.processValueOutput("SettingsEfficiencyLabel".localise(), value: .init("-m"), reverse:true))
                    
                    if SettingsManager.shared.enabledBeta == .enabled {
                        output.append(self.processValueOutput("Charge Limit", value: .init("-l"), reverse:true))
                        output.append(self.processValueOutput("Autopilot", value: .init("-a"), reverse:true))
                        
                    }

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
                    else if flags[1] == "-l" {
                        if let value = Int(flags[2]) {
                            BatteryManager.shared.powerChargeLimit(value)
                            
                            output.append(self.processHeaderOutput("SAVED", state:.sucsess))

                        }
                        else {
                            output.append(self.processHeaderOutput("INVALID TYPE", state:.error))

                        }
                        
                    }
                    else {
                        output.append(self.processHeaderOutput("MISSING FLAG", state:.error))

                        output.append(self.processValueOutput("Low Power Mode", value: .init("-m"), reverse:true))

                    }

                }

            }
            else if secondary == .health {
                let hasBattery = (BatteryManager.shared.info?.batteries ?? 0) > 0
                output.append("\n----------BATTERY HEALTH----------\n\n")

                if hasBattery == false {
                    output.append(self.processValueOutput("Status", value:.init("No battery installed")))
                    output.append("\n\u{001B}[90mThis device runs on AC power only.\u{001B}[0m\n")
                }
                else if let heath = BatteryManager.shared.health {
                    output.append(self.processValueOutput("Health State", value:.init(heath.state.rawValue, type: heath.state.warning)))
                    output.append(self.processValueOutput("Health Percentage", value:.init("\(Int(heath.percentage))%", type: heath.state.warning)))
                    output.append(self.processValueOutput("Cycle Count", value:.init("\(heath.cycles)")))
                    output.append(self.processValueOutput("Original Capacity", value:.init("\(Int(heath.capacity)) mAh")))
                    output.append(self.processValueOutput("Current Capacity", value:.init("\(Int(heath.available)) mAh")))
                }
                else {
                    output.append(self.processValueOutput("Health", value:.init("Unknown")))
                }

            }
            else if secondary == .thermal {
                let hasBattery = (BatteryManager.shared.info?.batteries ?? 0) > 0
                output.append("\n----------BATTERY TEMPERATURE----------\n\n")

                if hasBattery == false {
                    output.append(self.processValueOutput("Status", value:.init("No battery installed")))
                    output.append("\n\u{001B}[90mTemperature monitoring requires a battery.\u{001B}[0m\n")
                }
                else {
                    output.append(self.processValueOutput("Temperature", value:.init(BatteryManager.shared.thermal.formatted, type: BatteryManager.shared.thermal.state.warning)))
                    output.append(self.processValueOutput("Overheating", value:.init(BatteryManager.shared.thermal.state.flag.string(.yes), type: BatteryManager.shared.thermal.state.warning)))
                }

            }
            else if secondary == .time {
                let hasBattery = (BatteryManager.shared.info?.batteries ?? 0) > 0
                output.append("\n----------TIME REMAINING----------\n\n")

                if hasBattery == false {
                    output.append(self.processValueOutput("Status", value:.init("No battery installed")))
                    output.append("\n\u{001B}[90mThis device is always connected to power.\u{001B}[0m\n")
                }
                else if BatteryManager.shared.charging == .charging {
                    if let remaining = BatteryManager.shared.remaining {
                        output.append(self.processValueOutput("Time Until Full", value:.init(remaining.formatted ?? "Calculating...")))
                    }
                    else {
                        output.append(self.processValueOutput("Time Until Full", value:.init("Calculating...")))
                    }
                    output.append(self.processValueOutput("Current Charge", value:.init("\(BatteryManager.shared.percentage)%")))
                }
                else {
                    if let remaining = BatteryManager.shared.remaining {
                        output.append(self.processValueOutput("Time Until Empty", value:.init(remaining.formatted ?? "Calculating...")))
                    }
                    else {
                        output.append(self.processValueOutput("Time Until Empty", value:.init("Calculating...")))
                    }
                    output.append(self.processValueOutput("Current Charge", value:.init("\(BatteryManager.shared.percentage)%")))
                }

            }

        }
        else if command == .debug {
            if secondary == .info {
                output.append("\n----------GENERAL----------\n\n")
                
                output.append(self.processValueOutput("Installed On", value:.init( AppManager.shared.appInstalled.formatted)))
                output.append(self.processValueOutput("Device", value:.init( SystemDeviceTypes.name())))
                output.append(self.processValueOutput("Model", value:.init( SystemDeviceTypes.model)))
                output.append(self.processValueOutput("User ID", value: .init(SystemDeviceTypes.identifyer)))
                output.append(self.processValueOutput("Usage Count", value: .init(String(AppManager.shared.appUsage?.day ?? 0))))
                
                if SettingsManager.shared.enabledBeta == .enabled {
                    output.append(self.processValueOutput("Beta", value: .init(SettingsManager.shared.enabledBeta.subtitle, type: .sucsess)))

                }

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

//                for event in AppManager.shared.appListEvents(20) {
//                    output.append(self.processValueOutput("Notify", value: .init(event.notify)))
//                    output.append(self.processValueOutput("State", value: .init(event.state)))
//                    output.append(self.processValueOutput("Charge", value: .init("\(event.charge)")))
//
//                }
                
            }
            
        }
        else if command == .devices {
            if secondary == .list {
                if AppManager.shared.devices.isEmpty {
                    output.append("\n----------DEVICES----------\n\n")
                    output.append(self.processValueOutput("Status", value:.init("No devices found")))
                    output.append("\n\u{001B}[90mConnect Bluetooth devices to see them here.\u{001B}[0m\n")
                }
                else {
                    for device in AppManager.shared.devices {
                        output.append("\n----------DEVICE #\(device.order + 1)----------\n\n")

                        output.append(self.processValueOutput("ID", value:.init(device.id.uuidString)))
                        output.append(self.processValueOutput("Name", value: .init(device.name)))
                        output.append(self.processValueOutput("Added", value:.init("\(device.added?.formatted ?? "Unknown")")))
                        output.append(self.processValueOutput("Favourited", value: .init(device.favourite.string(.yes))))

                    }
                }

            }
            else if secondary == .set || secondary == .remove {
                if flags.indices.contains(1) == false || flags.indices.contains(2) == false{
                    output.append(self.processHeaderOutput("MISSING FLAG", state:.error))
                    
                    output.append(self.processValueOutput("Device Name", value: .init("-n"), reverse:true))
                    output.append(self.processValueOutput("Device ID", value: .init("-id"), reverse:true))
                    
                }
                else {
                    let device:SystemDeviceObject? = AppManager.shared.devices.first(where: { $0.name == flags[2] })
                    var response:String = ""
                
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
        else if command == .beta {
            if flags.first?.boolean == true {
                SettingsManager.shared.enabledBeta = .enabled

                output.append(self.processHeaderOutput("BETA ENABLED", state:.sucsess))

            }
            else {
                SettingsManager.shared.enabledBeta = .disabled

                output.append(self.processHeaderOutput("BETA DISABLED", state:.sucsess))

            }

        }
        else if command == .status {
            BatteryManager.shared.powerForceRefresh()

            let hasBattery = (BatteryManager.shared.info?.batteries ?? 0) > 0
            let deviceName = SystemDeviceTypes.name()

            output.append("\n\u{001B}[1;36m╔══════════════════════════════════════╗\u{001B}[0m\n")
            output.append("\u{001B}[1;36m║\u{001B}[0m            \u{001B}[1mBATTERY STATUS\u{001B}[0m            \u{001B}[1;36m║\u{001B}[0m\n")
            output.append("\u{001B}[1;36m╚══════════════════════════════════════╝\u{001B}[0m\n\n")

            output.append(self.processValueOutput("💻 Device", value:.init(deviceName)))

            if hasBattery {
                output.append(self.processValueOutput("🔌 Power Source", value:.init("Battery Powered")))

                let chargeIcon = BatteryManager.shared.charging == .charging ? "⚡" : "🔋"
                let chargeColor: ProcessResponseHeaderType
                if BatteryManager.shared.percentage <= 18 {
                    chargeColor = .error
                }
                else if BatteryManager.shared.percentage <= 25 {
                    chargeColor = .warning
                }
                else if BatteryManager.shared.charging == .charging {
                    chargeColor = .sucsess
                }
                else {
                    chargeColor = .normal
                }
                output.append(self.processValueOutput("\(chargeIcon) Charge", value:.init("\(BatteryManager.shared.percentage)%", type: chargeColor)))

                if BatteryManager.shared.charging == .charging {
                    output.append(self.processValueOutput("⏳ Status", value:.init("Charging", type: .sucsess)))
                    if let remaining = BatteryManager.shared.remaining, let formatted = remaining.formatted {
                        output.append(self.processValueOutput("⏱  Time to Full", value:.init(formatted)))
                    }
                }
                else {
                    output.append(self.processValueOutput("📊 Status", value:.init("On Battery")))
                    if let remaining = BatteryManager.shared.remaining, let formatted = remaining.formatted {
                        output.append(self.processValueOutput("⏱  Time Remaining", value:.init(formatted)))
                    }
                }

                output.append("\n")

                if let heath = BatteryManager.shared.health {
                    output.append(self.processValueOutput("❤️  Health", value:.init("\(Int(heath.percentage))% (\(heath.state.rawValue))", type: heath.state.warning)))
                    output.append(self.processValueOutput("🔄 Cycles", value:.init("\(heath.cycles)")))
                }

                output.append(self.processValueOutput("🌡  Temperature", value:.init(BatteryManager.shared.thermal.formatted, type: BatteryManager.shared.thermal.state.warning)))
                output.append(self.processValueOutput("⚡ Power Mode", value:.init(BatteryManager.shared.mode.flag ? "Low Power" : "Normal", type: BatteryManager.shared.mode.flag ? .sucsess : .normal)))
            }
            else {
                output.append(self.processValueOutput("🔌 Power Source", value:.init("AC Power (No Battery)", type: .sucsess)))
                output.append(self.processValueOutput("📊 Status", value:.init("Always Connected", type: .sucsess)))
            }

            output.append("\n")

            let storedDevices = AppManager.shared.devices.count
            let activeDevices = BluetoothManager.shared.broadcasting.filter({ $0.state == .connected }).count
            let totalDevices = max(storedDevices, activeDevices)
            output.append(self.processValueOutput("📱 Devices", value:.init("\(totalDevices) connected")))

            if totalDevices > 0 {
                for device in AppManager.shared.devices.prefix(3) {
                    output.append("    \u{001B}[90m• \(device.name)\u{001B}[0m\n")
                }
                if storedDevices > 3 {
                    output.append("    \u{001B}[90m... and \(storedDevices - 3) more\u{001B}[0m\n")
                }
            }

        }
        else if command == .power {
            if secondary == .mode {
                output.append("\n----------POWER MODE----------\n\n")

                output.append(self.processValueOutput("Low Power Mode", value:.init(BatteryManager.shared.mode.flag.string(.enabled), type: BatteryManager.shared.mode.flag ? .sucsess : .normal)))
                output.append(self.processValueOutput("Current Mode", value:.init(BatteryManager.shared.mode.rawValue)))

            }
            else if secondary == .toggle {
                if BatteryManager.shared.mode == .unavailable {
                    output.append("\n----------LOW POWER MODE----------\n\n")
                    output.append(self.processValueOutput("Status", value:.init("Unavailable", type: .warning)))
                    output.append("\n\u{001B}[90mLow Power Mode is not available on this device.\u{001B}[0m\n")
                }
                else {
                    let currentlyEnabled = BatteryManager.shared.mode == .efficient
                    let newState = currentlyEnabled == false
                    BatteryManager.shared.powerEfficiencyMode(newState ? .efficient : .normal)

                    if newState {
                        output.append(self.processHeaderOutput("LOW POWER MODE ENABLED", state:.sucsess))
                    }
                    else {
                        output.append(self.processHeaderOutput("LOW POWER MODE DISABLED", state:.warning))
                    }

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
                case .error:return " - \u{001B}[1;31m\(value.value)\u{001B}[0m - \(label)\n"
                case .sucsess:return " - \u{001B}[1;32m\(value.value)\u{001B}[0m - \(label)\n"
                case .normal:return " - \u{001B}[1m\(value.value)\u{001B}[0m - \(label)\n"
                case .warning: return " - \u{001B}[1;33m\(value.value)\u{001B} - \(label)\n"
                
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
