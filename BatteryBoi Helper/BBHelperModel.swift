//
//  BBHelperModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/9/23.
//

import Foundation

@objc enum HelperDependencies:Int {
    case homebrew
    case maccli
    
    var script:String {
        switch self {
            case .homebrew : return "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
            case .maccli : return "https://raw.githubusercontent.com/guarinogabriel/mac-cli/master/mac-cli/tools/install"
            
        }
        
    }
    
}

@objc enum HelperInstallerStatus:Int {
    case unknown = 0
    case okay = 200
    case malformedurl = 400
    case permission = 403
    case notfound = 410
    case unauthorized = 401
    
    init?(rawValue: String?) {
        if let int = Int(rawValue ?? ""), let status = HelperInstallerStatus(rawValue: int) {
            self = status

        }
        else {
            return nil
            
        }
        
    }
    
}

@objc enum HelperProcessType:Int {
    case run
    case launch
    
}

@objc enum HelperToggleState:Int {
    case unknown
    case enabled
    case disabled
    
}

@objc(HelperProtocol) protocol HelperProtocol {
    func helperDownloadDependancy(_ type:HelperDependencies, destination:URL, completion: @escaping (HelperInstallerStatus, String) -> Void)
    func helperToggleLowPower(_ state:HelperToggleState, completion: @escaping (HelperToggleState) -> Void)
    func helperPowerMode(completion: @escaping (HelperToggleState) -> Void)
    func helperVersion(completion:@escaping(NSNumber?) -> Void)
    func helperProcessTaskWithArguments(_ type:HelperProcessType, path:String, arguments:[String], whitespace:Bool, completion:@escaping(String?) -> Void)

}
