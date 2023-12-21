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
                onboarding.onboardingAction(.primary)
                
            }
            
        }
    
    }
    
}

#if os(macOS)
    struct OnboardingParent: View {
        @State var geo:GeometryProxy
        
        var screen = NSScreen.main!.visibleFrame
        var body: some View {
            OnboardingContainer()
                .offset(x: 0, y: -60)
                .frame(maxWidth: screen.size.width, maxHeight: screen.size.height + 60)
                .background(Color.green)
                .mask(
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.black)
                    
                )
                .ignoresSafeArea(.all, edges: .all)
        
        }
        
    }

    struct OnboardingHost: View {
        var body: some View {
            VStack {
                GeometryReader { geo in
                    OnboardingParent(geo: geo)
                    
                }
                
            }
            .environmentObject(AppManager.shared)
            .environmentObject(OnboardingManager.shared)
            .environmentObject(StatsManager.shared)
            .environmentObject(BluetoothManager.shared)
            .environmentObject(CloudManager.shared)
            .environmentObject(BatteryManager.shared)
            .environmentObject(SettingsManager.shared)
        
        }
        
    }

#endif


