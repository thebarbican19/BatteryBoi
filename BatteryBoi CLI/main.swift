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
let payload = try? JSONEncoder().encode(arguments.suffix(arguments.count - 1)) as CFData

if let message = CFMessagePortCreateRemote(nil, "com.batteryboi.cli" as CFString) {
    var unmanaged: Unmanaged<CFData>? = nil
    
    let status = CFMessagePortSendRequest(message, 0, payload, 3.0, 3.0, CFRunLoopMode.defaultMode.rawValue, &unmanaged)
    let cfdata = unmanaged?.takeRetainedValue()
    
    if status == kCFMessagePortSuccess {
        if let data = cfdata as Data?, let response = String(data: data, encoding: .utf8) {
            print(response)
            
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
    
    print("Opening BatteryBoi...")
    exit(1)
    
}

