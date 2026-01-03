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
        subcommands: [TerminalInteractive.self, TerminalBatteryCommand.self, TerminalDevicesCommand.self, TerminalMenubarCommand.self, TerminalSettingsCommand.self, TerminalPowerCommand.self, TerminalStatusCommand.self, TerminalLogCommand.self, TerminalIntroCommand.self, TerminalResetCommand.self, TerminalDeduplicateCommand.self, TerminalGithubCommand.self, TerminalRateCommand.self, TerminalWebsiteCommand.self, TerminalCameraCommand.self],
        defaultSubcommand: TerminalInteractive.self
    )
}

// MARK: - Interactive Mode Engine

class TerminalInteractiveSession {
    private var originalTermios = termios()
    private var isRawMode = false
    private var history: [String] = []
    private var commandList: [String] = [
        "status", "battery", "devices", "menubar", "settings", "power", "health", "thermal", "time", "help", "clear", "exit", "quit", "log", "intro", "reset", "deduplicate", "github", "rate", "website", "camera"
    ]
    
    // Input State
    private var inputBuffer: String = ""
    private var cursorIndex: Int = 0
    private var suggestionIndex: Int = 0
    private var filteredCommands: [String] = []
    private var isSlashMode = false
    
        func run() {
            printBanner()
            
            // Auto-run status command
            sendCommand(["status"])
            print("\n\(ANSIColor.cyan)Interactive Mode\(ANSIColor.reset) - Type '/' for commands or 'exit' to quit\n")
            
            enableRawMode()
            defer { disableRawMode() }
            
            while true {
                renderLine()
                
                let key = readKey()
                
                switch key {
                case .enter:
                    print() 
                    let command = inputBuffer.trimmingCharacters(in: .whitespaces)
                    
    if command.isEmpty == false {
        let process = Process()
        process.launchPath = "/bin/bash"
                        history.append(command)
                        if command == "exit" || command == "quit" {
                            return
                        }
                        
                        disableRawMode()
                        executeCommand(command)
                        enableRawMode()
                    }
                    
                    inputBuffer = ""
                    cursorIndex = 0
                    isSlashMode = false
                    
                case .backspace:
                    if cursorIndex > 0 {
                        let index = inputBuffer.index(inputBuffer.startIndex, offsetBy: cursorIndex - 1)
                        inputBuffer.remove(at: index)
                        cursorIndex -= 1
                        updateSlashState()
                    }
                    
                case .arrowUp:
                    if isSlashMode && !filteredCommands.isEmpty {
                        suggestionIndex = (suggestionIndex - 1 + filteredCommands.count) % filteredCommands.count
                    }
                    
                case .arrowDown:
                    if isSlashMode && !filteredCommands.isEmpty {
                        suggestionIndex = (suggestionIndex + 1) % filteredCommands.count
                    }
                    
                case .arrowLeft:
                    if cursorIndex > 0 {
                        cursorIndex -= 1
                    }
                    
                case .arrowRight:
                    if cursorIndex < inputBuffer.count {
                        cursorIndex += 1
                    }
                    
                case .tab:
                    if isSlashMode && !filteredCommands.isEmpty {
                        let selected = filteredCommands[suggestionIndex]
                        inputBuffer = "/" + selected + " "
                        cursorIndex = inputBuffer.count
                        isSlashMode = false
                    }
                    
                case .char(let c):
                    let index = inputBuffer.index(inputBuffer.startIndex, offsetBy: cursorIndex)
                    inputBuffer.insert(c, at: index)
                    cursorIndex += 1
                    updateSlashState()
                    
                case .esc:
                    isSlashMode = false
                    
                default:
                    break
                }
            }
        }
        
        private func updateSlashState() {
            if inputBuffer.starts(with: "/") {
                isSlashMode = true
                let query = String(inputBuffer.dropFirst()).lowercased()
                filteredCommands = commandList.filter { $0.starts(with: query) }
                suggestionIndex = 0
            }
            else {
                isSlashMode = false
            }
        }
        
            private func renderLine() {
                print("\u{001B}[2K\r", terminator: "")
                
                let promptSymbol = "›"
                let prompt = "\(ANSIColor.cyan)\(ANSIColor.bold)\(promptSymbol)\(ANSIColor.reset) "
                
                if inputBuffer.isEmpty {
                    let placeholder = "Type a command or '/' for menu"
                    print("\(prompt)\(ANSIColor.dim)\(placeholder)\(ANSIColor.reset)", terminator: "")
                    print("\u{001B}[\(placeholder.count)D", terminator: "")
                }
                else {
                    print("\(prompt)\(inputBuffer)", terminator: "")
                }
                
                if isSlashMode && !filteredCommands.isEmpty {
                    // DEC Save Cursor
                    print("\u{001B}7", terminator: "")
                    print("\n", terminator: "")
                    
                    let limit = 5
                    let start = max(0, min(suggestionIndex - limit/2, filteredCommands.count - limit))
                    let end = min(start + limit, filteredCommands.count)
                    
                    for i in start..<end {
                        let cmd = filteredCommands[i]
                        print("\u{001B}[2K", terminator: "")
                        
                        if i == suggestionIndex {
                            print("  \(ANSIColor.bgBlue)\(ANSIColor.white) \(cmd) \(ANSIColor.reset)")
                        }
                        else {
                            print("  \(ANSIColor.dim)\(cmd)\(ANSIColor.reset)")
                        }
                        print("\r\n", terminator: "")
                    }
                    
                    // DEC Restore Cursor
                    print("\u{001B}8", terminator: "")
                }
                
                let moveBack = inputBuffer.count - cursorIndex
                if moveBack > 0 {
                    print("\u{001B}[\(moveBack)D", terminator: "")
                }
                
                fflush(stdout)
            }        
            private func executeCommand(_ input: String) {
                // 1. Trim whitespace
                var cleanInput = input.trimmingCharacters(in: .whitespaces)
                
                // 2. Remove leading slash if present
                if cleanInput.hasPrefix("/") {
                    cleanInput = String(cleanInput.dropFirst())
                }
                
                // 3. Split into parts
                let parts = cleanInput.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map(String.init)
                guard let command = parts.first else {
                    return
                }
                
                // Prepare args (the first element is the command itself)
                var args = parts
        
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
                case "log":
                    sendCommand(["log", "export"])
                case "intro":
                    sendCommand(["intro", "show"])
                case "reset":
                    let action = args.count > 1 ? args[1] : "all"
                    sendCommand(["reset", action])
                case "github":
                    sendCommand(["github", "open"])
                case "rate":
                    sendCommand(["rate", "open"])
                case "website":
                    sendCommand(["website", "open"])
                case "camera":
                    sendCommand(["camera", "info"])
                case "clear":
                    print("\u{001B}[2J\u{001B}[H")
                case "banner":
                    printBanner()
                case "history":
                     for (index, cmd) in history.enumerated() {
                        print("  \(index + 1). \(cmd)")
                    }
                default:
                    print(formatError("Unknown command: '\(command)'."))
                }
            }        
        private func enableRawMode() {
            tcgetattr(STDIN_FILENO, &originalTermios)
            var raw = originalTermios
            raw.c_lflag &= ~UInt(ECHO | ICANON)
            
            // Set VMIN and VTIME for non-blocking reads if needed, 
            // but here we actually WANT blocking read for the first char, 
            // then non-blocking for escape sequence tail.
            // For simple raw mode, we keep defaults but we will handle logic in readKey.
            
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
            isRawMode = true
        }
        
        private func disableRawMode() {
            if isRawMode {
                tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
                isRawMode = false
            }
        }
        
        enum Key {
            case char(Character)
            case enter
            case backspace
            case arrowUp
            case arrowDown
            case arrowLeft
            case arrowRight
            case esc
            case tab
            case unknown
        }
        
        private func readKey() -> Key {
            var c: UInt8 = 0
            let readCount = read(STDIN_FILENO, &c, 1)
            if readCount == 0 { return .unknown }
            
            if c == 10 || c == 13 { return .enter }
            if c == 127 { return .backspace }
            if c == 9 { return .tab }
            if c == 27 {
                // Non-blocking read for sequence
                // We set non-blocking mode temporarily
                var flags = fcntl(STDIN_FILENO, F_GETFL)
                fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK)
                
                var seq = [UInt8](repeating: 0, count: 2)
                let n = read(STDIN_FILENO, &seq, 2)
                
                // Restore blocking
                fcntl(STDIN_FILENO, F_SETFL, flags)
                
                if n < 2 { return .esc }
                
                if seq[0] == 91 {
                    switch seq[1] {
                    case 65: return .arrowUp
                    case 66: return .arrowDown
                    case 67: return .arrowRight
                    case 68: return .arrowLeft
                    default: return .unknown
                    }
                }
                return .esc
            }
            
            return .char(Character(UnicodeScalar(c)))
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
        \(ANSIColor.green)log\(ANSIColor.reset)                     Application logs
        \(ANSIColor.green)camera, cam\(ANSIColor.reset)             Camera activity status
        \(ANSIColor.green)intro\(ANSIColor.reset)                   Show intro/onboarding window
        \(ANSIColor.green)reset [action]\(ANSIColor.reset)          Reset application data
          - onboarding, defaults, database, all
        \(ANSIColor.green)github, rate, website\(ANSIColor.reset)    Open project links

        \(ANSIColor.blue)history\(ANSIColor.reset)                 Show command history
        \(ANSIColor.blue)clear\(ANSIColor.reset)                   Clear screen
        \(ANSIColor.blue)banner\(ANSIColor.reset)                  Show banner
        \(ANSIColor.blue)help\(ANSIColor.reset)                    Show this help
        \(ANSIColor.red)exit, quit\(ANSIColor.reset)               Quit interactive mode
        """)
    }
}

struct TerminalInteractive: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "interactive",
        abstract: "Start interactive REPL mode with rich input and autocomplete"
    )

    mutating func run() throws {
        let session = TerminalInteractiveSession()
        session.run()
    }
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