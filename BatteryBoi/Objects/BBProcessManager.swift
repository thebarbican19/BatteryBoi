//
//  BBProcessManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/26/23.
//

import Foundation
import EnalogSwift

class ProcessManager:ObservableObject {
    static var shared = ProcessManager()
    
    @Published var state:ProcessPermissionState = .unknown
    
    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.processInstallScript()
            
        }
        #warning("Remove This for Onboarding State")
        
    }
    
    public func processInstallScript() {
        #if MAINTARGET
            if ToolInstaller.install() == true {
                DispatchQueue.main.async {
                    self.state = .allowed
                    
                }

            }
            else {
                DispatchQueue.main.async {
                    self.state = .denied
                    
                }
                
            }
        
        #endif
        
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
    
}
