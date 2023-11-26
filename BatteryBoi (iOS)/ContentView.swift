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

            Text("Polled: \(manager.polled?.description ?? "Never")")

        }
        .padding()
        .font(.caption)
        
        VStack {
            Text("Devices").font(.title)
            
            ScrollView {
                LazyVGrid(columns: layout, alignment: .leading, spacing:10) {
                    ForEach(manager.list, id: \.name) { device in
                        HStack {
                            Text(device.name)
                            
                            if let id = device.id {
                                Text(id.uuidString)

                            }

                        }
                        .background(.gray)
                        
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
