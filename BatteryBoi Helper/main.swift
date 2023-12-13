//
//  main.swift
//  BatteryBoi Helper
//
//  Created by Joe Barbour on 12/8/23.
//

import Foundation
import Cocoa
import os.log

final class HelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedObject = HelperManager.shared
        connection.interruptionHandler = {
           os_log("Helperboi connection interrupted")

        }
        connection.invalidationHandler = {
           os_log("Helperboi connection invalidated")

        }
        connection.resume()
        
        return true
        
    }
    
}

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: "com.ovatar.batteryapp.helperboi.mach")
listener.delegate = delegate
listener.resume()

RunLoop.current.run()
