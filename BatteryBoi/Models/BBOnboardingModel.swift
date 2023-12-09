//
//  BBOnboardingModel.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/28/23.
//

import Foundation

#if os(macOS)
    public enum OnboardingViewType:String {
        case intro
        case cloud
        case bluetooth
        case admin
        case cli
        case nobatt
        case ios
        case loginatlaunch
        case complete
        
        var present:Bool {
            switch self {
                case .intro : return true
                case .cloud : return true
                case .admin : return true
                case .nobatt : return true
                case .cli : return false
                case .bluetooth : return true
                case .ios : return false
                case .loginatlaunch : return false
                case .complete : return false

            }
            
        }
        
    }

#elseif os(iOS)
    public enum OnboardingViewType:String {
        case intro
        case notifications
        case cloud
        case bluetooth
        case macos
        case complete
        
        var present:Bool {
            switch self {
                case .intro : return true
                case .notifications : return true
                case .cloud : return true
                case .bluetooth : return true
                case .macos : return false
                case .complete : return false

            }
            
        }
        
    }

#endif

public enum OnboardingStepViewed {
    case seen
    case unseen
    
}
