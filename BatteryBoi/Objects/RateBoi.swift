//
//  RateBoi.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/7/23.
//

import Foundation
import Combine
import StoreKit

#if os(macOS)
    import AppKit
#endif

extension UserDefaults {
    static let updated = PassthroughSubject<RateDefaultsKeys, Never>()

    static var boi:UserDefaults {
        return UserDefaults()
        
    }

    static func store(_ key:RateDefaultsKeys, value:Any?) {
        if let value = value {
            boi.set(value, forKey: key.rawValue)
            boi.synchronize()
            
            updated.send(key)
                        
        }
        else {
            boi.removeObject(forKey: key.rawValue)
            boi.synchronize()

            updated.send(key)

        }
        
    }
    
    static func value(_ key:RateDefaultsKeys) -> Any? {
        return boi.value(forKey: key.rawValue)
        
    }
    
}


enum RateDefaultsKeys:String {
    case required = "ratetboi.points.required"
    case aquired = "ratetboi.points.aquired"
    case prompted = "ratetboi.prompted.timestamp"

}

enum RateErrorType:Int {
    case minor = 1
    case major = 3
    case fatal = 5
    
}

class RateBoi:ObservableObject {
    static var main = RateBoi()
        
    private var debug:Bool = false
    private var disabled:Bool = false
    
    public static var url:URL? {
        if let url = Bundle.main.infoDictionary?["BB_RATE_URL"] as? String {
            RateBoi.main.rateLog("Rate URL Updated - \(url)", status: 200)

            return URL(string: url)
            
        }
        
        return nil
        
    }
    
    private var cancellable = Set<AnyCancellable>()

    init() {
        UserDefaults.updated.receive(on: DispatchQueue.main).sink { key in
            // callback
//            switch key {
//            case .aquired : self.rateLog("Delight Score Min Limit Updated - \(points)/", status: 200)
//            case .required : self.rateLog("Delight Score Min Limit Updated - \(points)/", status: 200)
//            }
            //switch key {
            //self.rateLog("Delight Score Updated - \(existing + points)/", status: 200)

        }.store(in: &cancellable)
        
    }
    
    public func setup(points:Int? = nil, debug:Bool = true) {
        if debug == true {
            self.debug = debug
            self.rateLog("Debugging Enabled", status: 200)

        }

        if let points = points {
            if points > 0 {
                UserDefaults.store(.required, value: points)
                
            }
            else {
                
            }
            
        }
        
    }
    
    public func increment(_ points:Int? = nil) {
        if let existing = UserDefaults.value(.aquired) as? Int {
            if let points = points {
                UserDefaults.store(.aquired, value: existing + points)

            }
            else {
                
            }

        }

    }
    
    public func errorReport(_ error:RateErrorType = .minor) {
        if let existing = UserDefaults.value(.aquired) as? Int {
            UserDefaults.store(.aquired, value: existing - error.rawValue)

        }
        
    }
    
    public func ratingPrompted(completion: (Int) -> Void) {
//        UserDefaults.standard.set(Date(), forKey: RateDefaultsKeys.prompted.rawValue)
//        UserDefaults().synchronize()
//        
        completion(UserDefaults.standard.integer(forKey: RateDefaultsKeys.aquired.rawValue))

    }
    
    private func rateTrigger() {
        if let url = RateBoi.url {
            #if os(macOS)
                NSWorkspace.shared.open(url)
            
            #else
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    
                }
                else {
                    
                }
            
            #endif

        }
        else {
            #if os(macOS)
//                if let window = self.view.window {
//                    SKStoreReviewController.requestReview(in: window.scene)
//                    
//                }
            
            #else
                SKStoreReviewController.requestReview()

            #endif
            
        }
        
    }
    
    private func rateLog(_ text:String, status:Int) {
        if self.debug == true {
            switch status {
                case 200 : print("\n\n✅ RateBoi Client - \(text)\n\n")
                case 201 : print("\n\n✅ RateBoi Client - \(text)\n\n")
                default : print("\n\n🚨 RateBoi Client - \(status) \(text)\n\n")
                
            }
            
        }
        
    }
        
}
