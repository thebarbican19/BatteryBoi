//
//  main.swift
//  BatteryBoi CLI
//
//  Created by Joe Barbour on 12/4/23.
//

import Foundation
import AppKit
import CoreAudio

let version = 1.0
let arguments = CommandLine.arguments
let payload = try? JSONEncoder().encode(arguments) as CFData

var primary:ProcessPrimaryCommands? = nil
var secondary:ProcessSecondaryCommands? = nil

if arguments.indices.contains(1) {
    if let prompt = ProcessPrimaryCommands(rawValue: arguments[1]) {
        primary = prompt
        
    }
    else {
        print("\u{001B}[1m\(arguments[1])\u{001B}[0m is not a valid command.")

    }
    
}

if let command = primary {
    if arguments.indices.contains(2) {
        if let prompt = ProcessSecondaryCommands(rawValue: arguments[2]) {
            if command.secondary.first(where: { $0 == prompt}) != nil {
                secondary = prompt
                
            }
            
        }
        
    }
    else {
        secondary = command.secondary.first

    }
        
    if let secondary = secondary {
        if primary == .menubar {
            if secondary == .help {
                
            }
            else if secondary == .info {
                
            }
            
        }
        else if primary == .battery {
            if secondary == .info {
                responseHeaderOutput("INFO", state:.normal)

                print(" - Charge: \u{001B}[1m\(BatteryManager.shared.percentage)\u{001B}[0m / 100")
                print(" - Charging: \u{001B}[1m\(BatteryManager.shared.charging.state.charging ? "YES":"NO")\u{001B}[0m")

                if BatteryManager.shared.charging.state == .battery {
                    print(" - Last Charged: \u{001B}[1m\( BatteryManager.shared.charging.ended?.formatted ?? "Unknown")\u{001B}[0m")

                }
               
                if let metrics = BatteryManager.shared.metrics {
                    print(" - Cycles: \u{001B}[1m\(metrics.cycles.formatted)\u{001B}[0m")

                }
                
            }
            else if secondary == .help {
                
            }
            else {
                
            }
            
        }
        else if primary == .website {
            if let url = URL(string: "http://batteryboi.ovatar.io/index?ref=cliboi") {
                NSWorkspace.shared.open(url)
                
                responseHeaderOutput("SUCSESS", state:.sucsess)
                print(" - Opening URL: \(url.absoluteString)")
                
            }
            else {
                responseHeaderOutput("FAILED", state:.error)
                print(" - URL Unsupported")

            }
            
        }
        
    }
    else {
        responseHeaderOutput("UNSUPPORTED", state:.error)

        for supported in command.secondary {
            print(" - \(supported.rawValue)\n")

        }
        
    }

}

print("\n\n")
print("\u{001B}[90mcliboi 2024 Version \(version)\u{001B}[0m")
print("\n")

if let message = CFMessagePortCreateRemote(nil, "com.batteryboi.cli" as CFString) {
    var unmanaged: Unmanaged<CFData>? = nil
    
    let status = CFMessagePortSendRequest(message, 0, payload, 3.0, 3.0, CFRunLoopMode.defaultMode.rawValue, &unmanaged)
    let cfdata = unmanaged?.takeRetainedValue()
    
    if status == kCFMessagePortSuccess {
        if let data = cfdata as Data?, let _ = String(data: data, encoding: .utf8) {
            //print("This is an sucsess output" ,string)
            
        }
        else {
            print("couldn't convert data.")
            
        }
        
        exit(0)
        
    }
    else {
        print(status)
        
    }
    
}
else {
    if let symlink = Bundle.main.executablePath {
        let path = URL(filePath: symlink).resolvingSymlinksInPath()
        var components = path.pathComponents
        components.removeLast(3)
        
        let directory = URL(fileURLWithPath: "/" + components.joined(separator: "/"))
        let unmanaged = Unmanaged.passUnretained(directory as CFURL)
        
        var spec = LSLaunchURLSpec(appURL: unmanaged, itemURLs: nil, passThruParams: nil, launchFlags: [.dontSwitch], asyncRefCon: nil)
        
        LSOpenFromURLSpec(&spec, nil)
        
    }
    
    print("Port Error")
    exit(1)
    
}

func responseHeaderOutput(_ response:String, state:ProcessResponseHeaderType) {
    switch state {
        case .error : print("\u{001B}[1m\u{001B}[31m\(response)\u{001B}[0m")
        case .sucsess : print("\u{001B}[1m\u{001B}[32m\(response)\u{001B}[0m")
        case .normal : print("\u{001B}[1m\(response)\u{001B}[0m")

    }

}
