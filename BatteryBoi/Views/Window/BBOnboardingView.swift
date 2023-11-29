//
//  BBOnboardingView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/28/23.
//

import SwiftUI

struct OnboardingContainer: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var bluetooth:BluetoothManager
    @EnvironmentObject var icloud:CloudManager
    @EnvironmentObject var onboarding:OnboardingManager

    var body: some View {
        VStack {
            Text(onboarding.state.rawValue).onTapGesture {
                onboarding.onboardingAction()
                
            }
            
        }
    
    }
    
}
