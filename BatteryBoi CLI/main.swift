import Foundation
import AppKit

#if canImport(ArgumentParser)
import ArgumentParser
#endif

let cliVersion = "1.0.0"
let portName = "group.com.ovatar.batteryboi"

enum ANSIColor {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let cyan = "\u{001B}[36m"
    static let green = "\u{001B}[32m"
    static let red = "\u{001B}[31m"
    static let blue = "\u{001B}[34m"
    static let yellow = "\u{001B}[33m"
    static let magenta = "\u{001B}[35m"
}

struct BatteryBoiCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "cliboi",
        abstract: "BatteryBoi CLI - Monitor your device batteries from the command line",
        version: cliVersion,
        subcommands: [Interactive.self, BatteryCommand.self, DevicesCommand.self, MenubarCommand.self, SettingsCommand.self, PowerCommand.self, StatusCommand.self],
        defaultSubcommand: StatusCommand.self
    )
}

struct Interactive: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "interactive",
        abstract: "Start interactive REPL mode for easy battery monitoring"
    )

    mutating func run() throws {
        printBanner()
        print("\n\(ANSIColor.cyan)Interactive Mode\(ANSIColor.reset) - Type 'help' for commands or 'exit' to quit\n")

        var history: [String] = []

        while true {
            print("\(ANSIColor.magenta)battery\(ANSIColor.reset)> ", terminator: "")
            fflush(stdout)

            guard let input = readLine() else { break }
            let trimmed = input.trimmingCharacters(in: .whitespaces)

            if trimmed == "exit" || trimmed == "quit" {
                print("Goodbye!")
                break
            }

            if trimmed == "history" {
                if history.isEmpty {
                    print(formatInfo("No command history"))
                } else {
                    for (index, cmd) in history.enumerated() {
                        print("  \(index + 1). \(cmd)")
                    }
                }
                continue
            }

            if trimmed.isEmpty { continue }

            history.append(trimmed)
            let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map(String.init)

            executeInteractiveCommand(parts)
        }
    }

    private func executeInteractiveCommand(_ args: [String]) {
        guard let command = args.first else { return }

        switch command.lowercased() {
        case "help":
            printInteractiveHelp()
        case "status", "s":
            sendCommand(["status"])
        case "battery", "b":
            let action = args.count > 1 ? args[1] : "info"
            sendCommand(["battery", action])
        case "health", "h":
            sendCommand(["battery", "health"])
        case "thermal", "t":
            sendCommand(["battery", "thermal"])
        case "time", "countdown":
            sendCommand(["battery", "time"])
        case "devices", "d":
            let action = args.count > 1 ? args[1] : "list"
            sendCommand(["devices", action])
        case "power":
            let action = args.count > 1 ? args[1] : "mode"
            sendCommand(["power", action])
        case "menubar", "m":
            sendCommand(["menubar", "info"])
        case "settings":
            sendCommand(["settings", "info"])
        case "clear":
            print("\u{001B}[2J\u{001B}[H")
        case "banner":
            printBanner()
        default:
            print(formatError("Unknown command: '\(command)'. Type 'help' for available commands."))
        }
    }

    private func printInteractiveHelp() {
        print("""
        \(ANSIColor.cyan)\(ANSIColor.bold)Available Commands:\(ANSIColor.reset)

        \(ANSIColor.green)status, s\(ANSIColor.reset)                Show complete dashboard
        \(ANSIColor.green)battery, b [action]\(ANSIColor.reset)      Battery information
          - info, health, thermal, time
        \(ANSIColor.green)health, h\(ANSIColor.reset)               Battery health percentage
        \(ANSIColor.green)thermal, t\(ANSIColor.reset)              Battery temperature
        \(ANSIColor.green)time, countdown\(ANSIColor.reset)         Time until full/empty
        \(ANSIColor.green)devices, d [action]\(ANSIColor.reset)     Connected devices
        \(ANSIColor.green)power [action]\(ANSIColor.reset)          Power mode & low power toggle
        \(ANSIColor.green)menubar, m\(ANSIColor.reset)              Menubar settings
        \(ANSIColor.green)settings\(ANSIColor.reset)                App settings

        \(ANSIColor.blue)history\(ANSIColor.reset)                 Show command history
        \(ANSIColor.blue)clear\(ANSIColor.reset)                   Clear screen
        \(ANSIColor.blue)banner\(ANSIColor.reset)                  Show banner
        \(ANSIColor.blue)help\(ANSIColor.reset)                    Show this help
        \(ANSIColor.red)exit, quit\(ANSIColor.reset)               Quit interactive mode
        """)
    }
}

struct StatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show complete battery dashboard with all information"
    )

    mutating func run() throws {
        printBanner()
        sendCommand(["status"])
    }
}

struct BatteryCommand: ParsableCommand {
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

struct DevicesCommand: ParsableCommand {
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

struct MenubarCommand: ParsableCommand {
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

struct SettingsCommand: ParsableCommand {
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

struct PowerCommand: ParsableCommand {
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

func printBanner() {
    let line1 = "\(ANSIColor.cyan)\(ANSIColor.bold)"
    let line2 = "  ____              __  __            ____        __"
    let line3 = " / __ )____ _   __/ /_/ /____  _____/ __ )____  /"
    let line4 = "/ __  / __ \\ | / / __/ __/ _ \\/ ___/ __  / __ \\/"
    let line5 = "/ /_/ / /_/ / |/ / /_/ /_/  __/ /  / /_/ / /_/ /"
    let line6 = "/_____/\\____/|__/\\__/\\__/\\___/_/  /_____/\\____/"
    let line7 = "\(ANSIColor.reset)"
    print(line1)
    print(line2)
    print(line3)
    print(line4)
    print(line5)
    print(line6)
    print(line7)
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
                exit(0)
            } else {
                print(formatError("Received empty or malformed response from BatteryBoi."))
                exit(1)
            }
        } else {
            switch status {
            case kCFMessagePortSendTimeout: print(formatError("Request to BatteryBoi timed out."))
            case kCFMessagePortReceiveTimeout: print(formatError("Response from BatteryBoi timed out."))
            case kCFMessagePortIsInvalid: print(formatError("Communication port is invalid."))
            default: print(formatError("IPC communication failed with status code \(status)."))
            }
            exit(1)
        }
    } else {
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
        } else {
            print(formatError("BatteryBoi is not running and couldn't be located."))
        }
        exit(1)
    }
}

BatteryBoiCLI.main()
