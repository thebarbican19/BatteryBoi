//
//  BBHelperManager.swift
//  helperboi
//
//  Created by Joe Barbour on 12/9/23.
//

import Foundation

final class HelperManager: NSObject, HelperProtocol {
    static let shared = HelperManager()
    
    private var home: String? = nil
    private var directory: String? = nil

    func setupHomeDirectory(home: URL) {
        self.home = home.path()
        self.directory = "\(home.path())Library/Application Support/BatteryBoi/"
        
    }
    
    func setupExecutables(_ directory:String) {
        guard let bundle = self.directory, let file = directory.components(separatedBy: "/").last else {
            return

        }
        
        guard let formatted = directory.components(separatedBy: "file://").last else  {
            return
            
        }
        
        self.helperProcessTaskWithArguments(.run, path:"/bin/cp", arguments: [formatted, "\(bundle)\(file)"]) { _ in
            
        }
    
    }
    
    func helperInterfaceState(completion: @escaping (HelperInterfaceState) -> Void) {
        self.helperProcessTaskWithArguments(.launch, path: "/usr/local/bin/cliboi", arguments: ["-c", "debug"]) { response in
            guard let response = response else {
                completion(.missing)
                return
                
            }
            
            if response.contains("command not found") {
                completion(.missing)

            }
            else {
                completion(.installed)

            }
            
        }

    }
    
    func helperVersion(completion:(NSNumber?) -> Void) {
        if let version = Bundle.main.infoDictionary?["CFBundleVersionKey"] as? String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            
            completion(formatter.number(from: version.replacingOccurrences(of: ".", with: "")))
            
        }
        else {
            completion(nil)
            
        }
                
    }
    
    func helperDownloadDependancy(_ type: HelperDependencies, destination: URL, completion: @escaping (HelperInstallerStatus, String) -> Void) {
         if let formatted = destination.absoluteString.components(separatedBy: "//").last?.removingPercentEncoding {
            let path:String = "/usr/bin/curl"
            let arguments =  ["-o", formatted, "-s", "-w", "%{http_code}", type.script]
            
            self.helperProcessTaskWithArguments(.run, path: path, arguments: arguments) { response in
                 guard let status = HelperInstallerStatus(rawValue: response) else {
                     completion(.unknown, "")
                     return
                     
                 }
                 
                 if status.rawValue == 200 {
                     self.helperSetFilePermissions(formatted, completion: { status in
                         completion(status, formatted)

                     })
                     
                 }
                 
             }
                        
        }
        else {
            completion(.malformedurl, "")

        }
        
    }
    
    func helperWriteData(key: String, value: UInt8, completion: @escaping (HelperWriteDataStatus) -> Void) {
        do {
            try SMCKit.open()
            
            let key = SMCKit.getKey(key, type: DataTypes.UInt8)
            let bytes: SMCBytes = (value, UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                                   UInt8(0), UInt8(0))
            
            try SMCKit.writeData(key, data: bytes)
           
            completion(.okay)
            
        }
        catch {
            print("powerWriteData error" ,error)
            completion(.unauthorized)

        }
        
    }
    
    func helperRetriveDeviceCache(completion: @escaping (String) -> Void) {
        if let directory = self.directory {
            self.helperProcessTaskWithArguments(.launch, path: "/bin/bash", arguments: ["-c", "\(directory)/cache.sh"]) { xml in
                completion("\(directory)/cache.sh" ?? "NO XML")
                
            }
                    
        }
        else {
            completion("NO DIRECTORY")
            
        }
        
    }
    
    func helperToggleLowPower(_ state:HelperToggleState, completion: @escaping (HelperToggleState) -> Void) {
        let path = "/bin/bash/"
        var commands = ["-c"]

        switch state {
            case .enabled : commands.append("sudo pmset -a lowpowermode 1")
            case .disabled : commands.append("sudo pmset -a lowpowermode 0")
            default : break
            
        }
      
        self.helperProcessTaskWithArguments(.launch, path:path, arguments: commands, whitespace: true) { response in
            self.helperPowerMode { state in
                completion(state)

            }
            
        }
        
    }
    
    func helperPowerMode(completion: @escaping (HelperToggleState) -> Void) {
        self.helperProcessTaskWithArguments(.launch, path:"/bin/bash", arguments: ["-c", "pmset -g | grep lowpowermode"], whitespace: true) { response in
            switch response?.last {
                case "0" : completion(.disabled)
                case "1" : completion(.enabled)
                default : completion(.unknown)

            }
            
        }

        completion(.unknown)
        
    }
    
    func helperProcessTaskWithArguments(_ type:HelperProcessType, path:String, arguments:[String], whitespace:Bool = false, completion: @escaping (String?) -> Void) {
        let process = Process()
        process.launchPath = path
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        if type == .launch {
            process.launch()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            if whitespace == true {
                completion(String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines))
                
            }
            else {
                completion(String(data: data, encoding: .utf8))
                
            }
            
        }
        else {
            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
               
                if whitespace == true {
                    completion(String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines))

                }
                else {
                    completion(String(data: data, encoding: .utf8))

                }
                
            } 
            catch {
                completion("Error - \(error)")
                
            }
            
        }
                            
    }
    
    private func helperInstallScript(_ file:String, flags:String = "", completion: @escaping (String) -> Void) {
        let path = "/bin/bash"
        let arguments = ["-c", "\(flags) \(file.replacingOccurrences(of: " ", with: "\\ "))"]

        self.helperProcessTaskWithArguments(.run, path: path, arguments: arguments) { response in
            completion(response ?? "")

        }
                
    }
    
    private func helperGetBrowserPage() {
        //determine lengh of video and present alert if battery is too low
        //osascript -e 'tell application "Arc" to return URL of active tab of front window'
        
    }

    private func helperSetFilePermissions(_ file:String, completion: @escaping (HelperInstallerStatus) -> Void) {
        self.helperProcessTaskWithArguments(.run, path: "/bin/chmod", arguments: ["+x", file]) { response in
            switch response?.isEmpty {
                case true : completion(.okay)
                default :  completion(.permission)
                
            }
            
        }
        
    }
    
    private func helperHomeDirectory(_ completion: @escaping (String) -> Void) {
        self.helperProcessTaskWithArguments(.run, path: "/bin/bash", arguments: ["-c", "echo $HOME"], whitespace: true) { home in
            if let home = home {
                completion(home)
//                completion(URL(fileURLWithPath: "\(home)/Library/Application Support/BatteryBoi"))

            }
            else {
                completion("DUNNO")
                
            }
            
        }
        
    }
    
}
