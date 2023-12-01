//
//  ContentView.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 9/25/23.
//

import SwiftUI
import Combine

struct UpdatesView: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var onboarding:OnboardingManager
    @EnvironmentObject var battery:BatteryManager
    @EnvironmentObject var bluetooth:BluetoothManager
    @EnvironmentObject var cloud:CloudManager

    @State var present:Bool = false

    let layout = [GridItem(.flexible(minimum: 180, maximum: .infinity))]

    var body: some View {
        VStack {
            HStack {
                Text("Onboarding: \(onboarding.state.rawValue)")
                
                Text("Cloud State: \(cloud.syncing.rawValue)")

                Text("Devices: \(manager.list.count)")
                
                Text("Polled: \(manager.updated?.formatted ?? "Never")")
                
            }
            .padding()
            .font(.caption)
            
            VStack {
                ScrollView {
                    Text("Broadcasting").font(.title)
                    
                    LazyVGrid(columns: layout, alignment: .leading, spacing:10) {
                        ForEach(bluetooth.broadcasting, id: \.self) { device in
                            HStack {
                                Text(device.name ?? "No Name")
                                
                                Text("State: \(device.state.rawValue)")
                                
                            }
                            
                        }
                        
                    }
                    
                    Text("Devices").font(.title)
                    
                    LazyVGrid(columns: layout, alignment: .leading, spacing:10) {
                        ForEach(manager.list.sorted(by: { $0.polled ?? Date.distantPast > $1.polled ?? Date.distantPast }), id: \.self) { device in
                            HStack {
                                Text("(\(device.connectivity.rawValue))")
                                
                                Text(device.name)
                                
                                Text(device.polled?.formatted ?? "Never")
                                
                                Text("Events: \(device.events.count)")
                                
                            }
                            .background(.gray)
               
                            ForEach(device.events.prefix(5), id: \.self) { event in
                                HStack {
                                    Text("Charge: \(event.battery)")
                                    
                                    Text("Timestamp: \(event.created.formatted)")
                                    
                                    if let state = event.state {
                                        Text("State: \(state.rawValue)")

                                    }
                                    
                                }
                                .background(.gray.opacity(0.2))
                                .padding(.leading, 30)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
            Spacer()
            
            HStack {
                Text("Charge: \(battery.percentage)")
                
                Text("State: \(battery.charging.state.rawValue)")
                
            }
            .padding()
            .font(.caption)
            
        }
        .sheet(isPresented: $present) {
            OnboardingContainer()
                .presentationDragIndicator(onboarding.state.required ? .hidden : .visible)
                .interactiveDismissDisabled(onboarding.state.required)

        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.present = self.onboarding.state.present
                
            }
            
        }
        .onChange(of: self.onboarding.state, perform: { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.present = newValue.present
                
            }

        })
                  
    }
    
}

struct ContentView: View {
    var body: some View {
        UpdatesView()
            .environmentObject(AppManager.shared)
            .environmentObject(OnboardingManager.shared)
            .environmentObject(StatsManager.shared)
            .environmentObject(BluetoothManager.shared)
            .environmentObject(CloudManager.shared)
            .environmentObject(BatteryManager.shared)
            .environmentObject(SettingsManager.shared)

    }
    
}
