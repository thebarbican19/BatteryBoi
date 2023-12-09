//
//  main.swift
//  BatteryBoi Helper
//
//  Created by Joe Barbour on 12/8/23.
//

import Foundation

final class HelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
//        newConnection.exportedInterface = NSXPCInterface(with: HelperToolProtocol.self)
//        newConnection.exportedObject = HelperTool.instance
        newConnection.resume()
        return true
    }
    
}

let listener = NSXPCListener(machServiceName: "com.ovatar.batteryapp.helperboi.mach")
//listener.delegate = delegate
listener.resume()

RunLoop.current.run()
