//
//  BBOnboardingModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/28/23.
//

import Foundation

public enum OnboardingViewType:String {
    case intro
    case notifications
    case cloud
    case bluetooth
    case none
    
    var present:Bool {
        switch self {
            case .intro : return true
            case .notifications : return true
            case .cloud : return true
            case .bluetooth : return true
            case .none : return false

        }
        
    }
    
    var required:Bool {
        switch self {
            case .intro : return false
            case .notifications : return true
            case .cloud : return true
            case .bluetooth : return true
            case .none : return false

        }
        
    }
    
}
