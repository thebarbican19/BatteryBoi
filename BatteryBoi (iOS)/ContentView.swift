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
    @EnvironmentObject var bluetooth:BluetoothManager
    @EnvironmentObject var icloud:CloudManager
    @EnvironmentObject var battery:BatteryManager

    let layout = [GridItem(.flexible(minimum: 180, maximum: .infinity))]

    var body: some View {
        HStack {
            Text("Bluetooth: \(bluetooth.state.rawValue)")
            
            Text("iCloud: \(icloud.state.rawValue)")

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
                    ForEach(manager.list, id: \.self) { device in
                        if device.name.isEmpty && device.id.uuidString.isEmpty {
                            Rectangle()
                            
                        }
                        else {
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

                                }
                                .background(.gray.opacity(0.2))
                                .padding(.leading, 30)
                                
                            }
                            
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
    
}

struct ContentView: View {
    var body: some View {
        UpdatesView()
            .environmentObject(AppManager.shared)
            .environmentObject(StatsManager.shared)
            .environmentObject(BluetoothManager.shared)
            .environmentObject(CloudManager.shared)
            .environmentObject(BatteryManager.shared)
            .environmentObject(SettingsManager.shared)

    }
    
}
