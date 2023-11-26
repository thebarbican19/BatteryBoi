//
//  BBProcessManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/26/23.
//

import Foundation
import EnalogSwift

enum ProcessState {
    case idle
    case waiting
    case failed
    case complete
    
}

class ProcessManager:ObservableObject {
    static var shared = ProcessManager()
    
    @Published var charging:ProcessState = .idle
    
    init() {
        
    }
    
    public func processWithArguments(_ path:String, arguments:[String], whitespace:Bool = false) -> String? {
        let process = Process()
        process.launchPath = path
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.launch()
            
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
            
        }
        catch {
            EnalogManager.main.ingest(SystemEvents.fatalError, description: error.localizedDescription)
            
        }
        
        return nil
                
    }
    
    public func processWithScript(_ script:String) -> String? {
        if FileManager.default.fileExists(atPath: "/usr/bin/python3") {
            if let script = Bundle.main.path(forResource: script, ofType: "py") {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
                process.arguments = [script]
                
                let pipe = Pipe()
                process.standardOutput = pipe

                do {                    
                    try process.run()
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    
                    if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        return output
                        
                    }
                    
                }
                catch {
                    EnalogManager.main.ingest(SystemEvents.fatalError, description: error.localizedDescription)

                }
                
            }
            
        }
        
        return nil
        
    }
    
}
