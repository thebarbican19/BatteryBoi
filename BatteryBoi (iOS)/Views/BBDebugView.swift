//
//  ContentView.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 9/25/23.
//

import SwiftUI
import Combine

struct DebugDeviceCell: View {
    @EnvironmentObject var manager:AppManager

    @State var revealed:Bool = true
    @State var device:SystemDeviceObject
    
    init(_ device: SystemDeviceObject, revealed: Bool = true) {
        self._device = State(initialValue: device)
        self._revealed = State(initialValue: revealed)

    }
    
    var body: some View {
        VStack {
            HStack {
                Text("(\(device.connectivity.rawValue))")
                
                Text(device.name)
                
                //Text(device.polled?.formatted ?? "Never")
                
                Text("Is System: \(device.system.string(.yes))")

//                Text("Events: \(device.events.count)")
                
            }
            .background(.gray)
            
            if revealed == true {
                ForEach(manager.events.filter({ $0.device == device }).prefix(5), id: \.self) { event in
                    HStack {
                        Text("Charge: \(event.battery)")
                        
                        Text("Timestamp: \(event.created.formatted)")
                        
                        if let state = event.state {
                            Text("State: \(state.rawValue)")
                            
                        }
                        
                    }
                    .background(event.notify == .alert ? .blue.opacity(0.4) : .gray.opacity(0.2))
                    .padding(.leading, 30)
                    
                }
                
            }
            
        }
        .onTapGesture {
            withAnimation(.easeInOut) {
                self.revealed.toggle()
                
            }
            
        }
        
    }
    
}

struct DebugDeviceView: View {
    @EnvironmentObject var manager:AppManager

    let layout = [GridItem(.flexible(minimum: 180, maximum: .infinity))]

    var body: some View {
        Text("Devices & Events").font(.title)

        LazyVGrid(columns: layout, alignment: .leading, spacing:10) {
            ForEach(manager.devices, id: \.self) { device in
                DebugDeviceCell(device)
                
            }
            
        }
        
    }
    
}

struct DebugBroadcastCell: View {
    @State var device:BluetoothBroadcastItem
    @State var revealed:Bool = true
    
    init(_ device: BluetoothBroadcastItem, revealed: Bool = true) {
        self._device = State(initialValue: device)
        self._revealed = State(initialValue: revealed)
        
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(device.peripheral.name ?? "No Name")
                
                Text("State: \(device.state.rawValue)")
                
                Text("Proximity: \(device.proximity.string ?? "Unknown")")

            }
            .background(.gray)
            
            if revealed == true {
                VStack {
//                    ForEach(device.characteristics, id: \.self) { item in
//                        HStack {
//                            Text(item)
//                            
//                        }
//                        .background(.gray.opacity(0.2))
//                        .padding(.leading, 30)
//                        
//                    }
                    
                }
                
            }
            
        }
        .id(device.id)
        .onTapGesture {
            withAnimation(.easeInOut) {
                self.revealed.toggle()
                
            }
            
        }
        
    }
    
}

struct DebugBroadcastView: View {
    @EnvironmentObject var bluetooth:BluetoothManager

    let layout = [GridItem(.flexible(minimum: 180, maximum: .infinity))]

    var body: some View {
        HStack() {
            Text("Broadcasting")
                .frame(alignment: .leading)
                .font(.title)
            
            if bluetooth.proximity == .proximate {
                Button("Wide Search") {
                    bluetooth.proximity = .far
                    
                }
                
            }

        }
        
        LazyVGrid(columns: layout, alignment: .leading, spacing:10) {
            ForEach(bluetooth.broadcasting, id: \.self) { device in
                DebugBroadcastCell(device)
                
            }
            
        }
        
    }
    
}

struct DebugContainer: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var onboarding:OnboardingManager
    @EnvironmentObject var battery:BatteryManager
    @EnvironmentObject var cloud:CloudManager

    @State var present:Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Onboarding: \(onboarding.state.rawValue)")
                
                Text("Cloud State: \(cloud.syncing.rawValue)")

                Text("Devices: \(manager.devices.count)")
                
                Text("Polled: \(manager.updated?.formatted ?? "Never")")
                
            }
            .padding()
            .font(.caption)
            
            VStack {
                ScrollView {
                    DebugBroadcastView()
                    
                    DebugDeviceView()
                    
                }
                
            }
            
            Spacer()
            
            HStack {
                Text("Charge: \(battery.percentage)")
                
                Text("State: \(battery.charging.rawValue)")
                
            }
            .padding()
            .font(.caption)
            
        }
        .sheet(isPresented: $present) {
            OnboardingContainer()
           
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
