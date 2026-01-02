//
//  BBNavigationView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/4/23.
//

import Foundation
import SwiftUI

struct NavigationContainer:View {
    @State var visibility:NavigationSplitViewVisibility = .doubleColumn

    var body: some View {
        VStack {
            if UIDevice.current.userInterfaceIdiom == .pad {
                NavigationSplitView(columnVisibility: $visibility) {
                    SettingContainer()
                    
                } detail: {
                    DebugContainer()
                    
                }
                .navigationBarBackButtonHidden(true)
                .navigationSplitViewStyle(.balanced)
                
            }
            else {
                DebugContainer()

            }

        }
        .environmentObject(AppManager.shared)
        .environmentObject(OnboardingManager.shared)
        .environmentObject(StatsManager.shared)
        .environmentObject(BluetoothManager.shared)
		.environmentObject(HomeKitManager.shared)
        .environmentObject(CloudManager.shared)
        .environmentObject(BatteryManager.shared)
        .environmentObject(SettingsManager.shared)
        
    }
    
}
