//
//  BBOnboardingConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation

public enum OnboardingActionType {
    case primary
    case secondary
    case dismiss
}

public enum OnboardingViewType: String {
    case intro
    case cloud
    case bluetooth
    case process
    case nobatt
    case hideicon
    case notifications
    case loginatlaunch
    case ios
    case macos
    case homekit
    case complete

    var present: Bool {
        switch self {
            case .intro: return true
            case .cloud: return true
            case .process: return true
            case .nobatt: return true
            case .hideicon: return true
            case .bluetooth: return true
            case .notifications: return true
            case .loginatlaunch: return true
            case .ios: return true
            case .macos: return true
            case .homekit: return true
            case .complete: return false
        }
    }
}

public enum OnboardingStepViewed {
    case seen
    case unseen
}
