//
//  BBOnboardingView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 11/28/23.
//

import SwiftUI

struct OnboardingPage: View {
    var icon: String
    var title: String
    var subtitle: String
    var primary: String
    var secondary: String? = nil
    var action: (OnboardingActionType) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button(action: { action(.primary) }) {
                    Text(primary)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                if let secondary = secondary {
                    Button(action: { action(.secondary) }) {
                        Text(secondary)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
    }
}

struct OnboardingContainer: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var bluetooth:BluetoothManager
    @EnvironmentObject var icloud:CloudManager
    @EnvironmentObject var onboarding:OnboardingManager
    
    @ViewBuilder
    var activePage: some View {
        if onboarding.state == .intro {
            OnboardingPage(
                icon: "battery.100",
                title: "OnboardingIntroTitle".localise(),
                subtitle: "OnboardingIntroSubtitle".localise(),
                primary: "OnboardingIntroButton".localise(),
                action: onboarding.onboardingAction
            )
        }
        else if onboarding.state == .bluetooth {
            OnboardingPage(
                icon: "antenna.radiowaves.left.and.right",
                title: "OnboardingBluetoothTitle".localise(),
                subtitle: "OnboardingBluetoothSubtitle".localise(),
                primary: "OnboardingBluetoothButton".localise(),
                secondary: "OnboardingBluetoothSecondaryButton".localise(),
                action: onboarding.onboardingAction
            )
        }
        else if onboarding.state == .cloud {
            #if os(iOS)
                OnboardingPage(
                    icon: "laptopcomputer",
                    title: "OnboardingMacTitle".localise(),
                    subtitle: manager.hasMacDevice ? "OnboardingMacDetectedSubtitle".localise() : "OnboardingMacMissingSubtitle".localise(),
                    primary: "OnboardingMacButton".localise(),
                    action: onboarding.onboardingAction
                )
            #else
                OnboardingPage(
                    icon: "icloud",
                    title: "OnboardingCloudTitle".localise(),
                    subtitle: "OnboardingCloudSubtitle".localise(),
                    primary: "OnboardingCloudButton".localise(),
                    secondary: "OnboardingCloudSecondaryButton".localise(),
                    action: onboarding.onboardingAction
                )
            #endif
        }
        else {
            platformSpecificPage
        }
    }
    
    @ViewBuilder
    var platformSpecificPage: some View {
        #if os(macOS)
        if onboarding.state == .process {
            OnboardingPage(
                icon: "gearshape.2",
                title: "OnboardingProcessTitle".localise(),
                subtitle: "OnboardingProcessSubtitle".localise(),
                primary: "OnboardingProcessButton".localise(),
                secondary: "OnboardingProcessSecondaryButton".localise(),
                action: onboarding.onboardingAction
            )
        }
        else if onboarding.state == .loginatlaunch {
            OnboardingPage(
                icon: "arrow.right.circle",
                title: "OnboardingLoginTitle".localise(),
                subtitle: "OnboardingLoginSubtitle".localise(),
                primary: "OnboardingLoginPrimaryButton".localise(),
                secondary: "OnboardingLoginSecondaryButton".localise(),
                action: onboarding.onboardingAction
            )
        }
        else if onboarding.state == .nobatt {
            OnboardingPage(
                icon: "battery.0",
                title: "OnboardingNoBatteryTitle".localise(),
                subtitle: "OnboardingNoBatterySubtitle".localise(),
                primary: "OnboardingNoBatteryButton".localise(),
                action: onboarding.onboardingAction
            )
        }
        else if onboarding.state == .ios {
            OnboardingPage(
                icon: "iphone",
                title: "OnboardingIOSTitle".localise(),
                subtitle: "OnboardingIOSSubtitle".localise(),
                primary: "OnboardingIOSButton".localise(),
                action: onboarding.onboardingAction
            )
        }
        else {
            EmptyView()
        }
        #elseif os(iOS)
        if onboarding.state == .notifications {
            OnboardingPage(
                icon: "bell.badge",
                title: "OnboardingNotificationsTitle".localise(),
                subtitle: "OnboardingNotificationsSubtitle".localise(),
                primary: "OnboardingNotificationsButton".localise(),
                secondary: "OnboardingNotificationsSecondaryButton".localise(),
                action: onboarding.onboardingAction
            )
        }
        else if onboarding.state == .macos {
            OnboardingPage(
                icon: "laptopcomputer",
                title: "OnboardingMacOSTitle".localise(),
                subtitle: "OnboardingMacOSSubtitle".localise(),
                primary: "OnboardingMacOSButton".localise(),
                action: onboarding.onboardingAction
            )
        }
        else {
            EmptyView()
        }
        #endif
    }
        
    var body: some View {
        VStack {
            if onboarding.state == .complete {
                Text("OnboardingCompleteLabel".localise())
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
            }
            else {
                activePage
            }
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .background(Color.green)
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Button(action: { 
                withAnimation {
                    onboarding.state = .complete 
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.5))
                    .padding()
            }
        }
        #endif
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


