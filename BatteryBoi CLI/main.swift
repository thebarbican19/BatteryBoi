import Foundation
import AppKit
import Darwin

#if canImport(ArgumentParser)
import ArgumentParser
#endif

let cliVersion = "1.0.0"
let portName = "group.com.ovatar.batteryboi"

enum ANSIColor {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    static let cyan = "\u{001B}[36m"
    static let green = "\u{001B}[32m"
    static let red = "\u{001B}[31m"
    static let blue = "\u{001B}[34m"
    static let yellow = "\u{001B}[33m"
    static let magenta = "\u{001B}[35m"
    static let white = "\u{001B}[37m"
    static let bgBlue = "\u{001B}[44m"
}

struct TerminalBatteryBoiCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cliboi",
        abstract: "BatteryBoi CLI - Monitor your device batteries from the command line",
        version: cliVersion,
        subcommands: [TerminalBatteryCommand.self, TerminalDevicesCommand.self, TerminalMenubarCommand.self, TerminalSettingsCommand.self, TerminalPowerCommand.self, TerminalStatusCommand.self, TerminalLogCommand.self, TerminalIntroCommand.self, TerminalResetCommand.self, TerminalDeduplicateCommand.self, TerminalGithubCommand.self, TerminalRateCommand.self, TerminalWebsiteCommand.self, TerminalCameraCommand.self, TerminalAlertsCommand.self],
        defaultSubcommand: TerminalStatusCommand.self
    )
}

struct TerminalStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show complete battery dashboard with all information"
    )

    mutating func run() throws {
        printBanner()
        sendCommand(["status"])
    }
}

struct TerminalBatteryCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "battery",
        abstract: "Battery information and details"
    )

    @Argument(help: "Action: info, health, thermal, or time")
    var action: String = "info"

    mutating func run() throws {
        sendCommand(["battery", action])
    }
}

struct TerminalDevicesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "devices",
        abstract: "Manage and list connected devices"
    )

    @Argument(help: "Action: list")
    var action: String = "list"

    mutating func run() throws {
        sendCommand(["devices", action])
    }
}

struct TerminalMenubarCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "menubar",
        abstract: "Menubar settings and display configuration"
    )

    @Argument(help: "Action: info")
    var action: String = "info"

    mutating func run() throws {
        sendCommand(["menubar", action])
    }
}

struct TerminalSettingsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "settings",
        abstract: "App settings and preferences"
    )

    @Argument(help: "Action: info")
    var action: String = "info"

    mutating func run() throws {
        sendCommand(["settings", action])
    }
}

struct TerminalPowerCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "power",
        abstract: "Power mode management and low power toggle"
    )

    @Argument(help: "Action: mode or toggle")
    var action: String = "mode"

    mutating func run() throws {
        sendCommand(["power", action])
    }
}

struct TerminalLogCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "log",
        abstract: "View application logs"
    )

    @Argument(help: "Action: export")
    var action: String = "export"

    mutating func run() throws {
        sendCommand(["log", action])
    }
}

struct TerminalIntroCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "intro",
        abstract: "Show the intro/onboarding window"
    )

    @Argument(help: "Action: show")
    var action: String = "show"

    mutating func run() throws {
        sendCommand(["intro", action])
    }
}

struct TerminalResetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Reset application data"
    )

    @Argument(help: "Action: onboarding, defaults, database, or all")
    var action: String = "all"

    mutating func run() throws {
        sendCommand(["reset", action])
    }
}

struct TerminalDeduplicateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "deduplicate",
        abstract: "Remove duplicate devices and merge their battery events"
    )

    mutating func run() throws {
        sendCommand(["deduplicate"])
    }
}

struct TerminalGithubCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "github",
        abstract: "Open BatteryBoi GitHub repository"
    )

    @Argument(help: "Action: open")
    var action: String = "open"

    mutating func run() throws {
        sendCommand(["github", action])
    }
}

struct TerminalRateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rate",
        abstract: "Rate BatteryBoi on ProductHunt"
    )

    @Argument(help: "Action: open")
    var action: String = "open"

    mutating func run() throws {
        sendCommand(["rate", action])
    }
}

struct TerminalWebsiteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "website",
        abstract: "Open BatteryBoi website"
    )

    @Argument(help: "Action: open")
    var action: String = "open"

    mutating func run() throws {
        sendCommand(["website", action])
    }
}

struct TerminalCameraCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "camera",
        abstract: "Camera activity and status information"
    )

    @Argument(help: "Action: info")
    var action: String = "info"

    mutating func run() throws {
        sendCommand(["camera", action])
    }
}

struct TerminalAlertsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "alerts",
        abstract: "Test and trigger alerts for development"
    )

    @Argument(help: "Action: trigger")
    var action: String = "trigger"

    @Argument(help: "Alert type to trigger")
    var alertType: String = ""

    mutating func run() throws {
        if alertType.isEmpty {
            sendCommand(["alerts", action])

        }
        else {
            sendCommand(["alerts", action, alertType])

        }

    }
}

func printBanner() {
    print("\(ANSIColor.cyan)\(ANSIColor.bold)")
    print(" ▄████▄   ██▓     ██▓ ▄▄▄▄    ▒█████   ██▓")
    print("▒██▀ ▀█  ▓██▒    ▓██▒▓█████▄ ▒██▒  ██▒▓██▒")
    print("▒▓█    ▄ ▒██░    ▒██▒▒██▒ ▄██▒██░  ██▒▒██▒")
    print("▒▓▓▄ ▄██▒▒██░    ░██░▒██░█▀  ▒██   ██░░██░")
    print("▒ ▓███▀ ░░██████▒░██░░▓█  ▀█▓░ ████▓▒░░██░")
    print("░ ░▒ ▒  ░░ ▒░▓  ░░▓  ░▒▓███▀▒░ ▒░▒░▒░ ░▓  ")
    print("  ░  ▒   ░ ░ ▒  ░ ▒ ░▒░▒   ░   ░ ▒ ▒░  ▒ ░")
    print("░          ░ ░    ▒ ░ ░    ░ ░ ░ ░ ▒   ▒ ░")
    print("░ ░          ░  ░ ░   ░          ░ ░   ░  ")
    print("░                          ░              ")
    print("\(ANSIColor.reset)")
}

func formatSuccess(_ message: String) -> String {
    return "\(ANSIColor.green)✓ \(message)\(ANSIColor.reset)"
}

func formatError(_ message: String) -> String {
    return "\(ANSIColor.red)✗ \(message)\(ANSIColor.reset)"
}

func formatInfo(_ message: String) -> String {
    return "\(ANSIColor.blue)ℹ \(message)\(ANSIColor.reset)"
}

func formatWarning(_ message: String) -> String {
    return "\(ANSIColor.yellow)⚠ \(message)\(ANSIColor.reset)"
}

func sendCommand(_ args: [String]) {
    let payload = try? JSONEncoder().encode(args) as CFData

    if let message = CFMessagePortCreateRemote(nil, portName as CFString) {
        var unmanaged: Unmanaged<CFData>? = nil

        let status = CFMessagePortSendRequest(message, 0, payload, 3.0, 3.0, CFRunLoopMode.defaultMode.rawValue, &unmanaged)
        let cfdata = unmanaged?.takeRetainedValue()

        if status == kCFMessagePortSuccess {
            if let data = cfdata as Data?, let response = String(data: data, encoding: .utf8) {
                print(response)
            }
            else {
                print(formatError("Received empty or malformed response from BatteryBoi."))
                exit(1)
            }
        }
        else {
            switch status {
            case kCFMessagePortSendTimeout: print(formatError("Request to BatteryBoi timed out."))
            case kCFMessagePortReceiveTimeout: print(formatError("Response from BatteryBoi timed out."))
            case kCFMessagePortIsInvalid: print(formatError("Communication port is invalid."))
            default: print(formatError("IPC communication failed with status code \(status)."))
            }
            exit(1)
        }
    }
    else {
        if let symlink = Bundle.main.executablePath {
            let path = URL(fileURLWithPath: symlink).resolvingSymlinksInPath()
            var components = path.pathComponents
            if components.count >= 4 {
                components.removeLast(3)
                let appPath = components.joined(separator: "/")
                let appURL = URL(fileURLWithPath: appPath)

                print(formatInfo("BatteryBoi is not running. Attempting to launch..."))
                NSWorkspace.shared.open(appURL)
                sleep(2)
                sendCommand(args)
            }
        }
        else {
            print(formatError("BatteryBoi is not running and couldn't be located."))
        }
        exit(1)
    }
}

TerminalBatteryBoiCLI.main()