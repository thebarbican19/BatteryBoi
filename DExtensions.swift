//
//  Extensions.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/6/23.
//

import Foundation
import SwiftUI
import Combine

extension String {
    public func append(_ string:String, seporator:String) -> String {
        return "\(self)\(seporator)\(string)"
        
    }
    
}

extension View {
    func inverse<M: View>(_ mask: M) -> some View {
        let inversed = mask
            .foregroundColor(.black)
            .background(Color.white)
            .compositingGroup()
            .luminanceToAlpha()
        
        return self.mask(inversed)
        
    }
    
}

extension UserDefaults {
    static let changed = PassthroughSubject<SystemDefaultsKeys, Never>()

    static var main:UserDefaults {
        return UserDefaults()
        
    }
    
    static var list:Array<SystemDefaultsKeys> {
        return UserDefaults.main.dictionaryRepresentation().keys.compactMap({ SystemDefaultsKeys(rawValue:$0) })
        
    }

    static func save(_ key:SystemDefaultsKeys, value:Any?) {
        if let value = value {
            main.set(Date(), forKey: "\(key.rawValue)_timestamp")
            main.set(value, forKey: key.rawValue)
            main.synchronize()
            
            changed.send(key)

            print("\n\n💾 Saved \(value) to '\(key.rawValue)'\n\n")
            
        }
        else {
            main.removeObject(forKey: key.rawValue)
            main.synchronize()

            changed.send(key)

        }
        
    }
    
}
