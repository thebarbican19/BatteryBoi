//
//  ContentView.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 9/25/23.
//

import SwiftUI
import Combine
import SwiftData

struct DebugDeviceEventsList: View {
    @Query var events: [BatteryObject]
    
    init(deviceId: UUID) {
        let predicate = #Predicate<BatteryObject> { $0.device?.id == deviceId }
        _events = Query(filter: predicate, sort: \.created, order: .reverse)
    }
    
    var body: some View {
        if events.isEmpty == true {
            Text("No events recorded")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 10)
                .padding(.bottom, 5)
        }
        else {
            ForEach(events.prefix(5)) { event in
                HStack {
                    Text("Charge: \(event.percent ?? 0)%")
                        .bold()
                    
                    if let created = event.created {
                        Text(created.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let state = event.state {
                        Text(state)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
}

struct DebugDeviceCell: View {
    @EnvironmentObject var manager: AppManager
    @State var revealed: Bool
    let device: AppDeviceObject
    
    init(_ device: AppDeviceObject, revealed: Bool = true) {
        self.device = device
        self._revealed = State(initialValue: revealed)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(device.connectivity == .system ? Color.green : Color.blue)
                    .frame(width: 8, height: 8)
                
                Text(device.name)
                    .font(.headline)
                
                Spacer()
                
                Text(device.connectivity == .system ? "System" : "Bluetooth")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut) {
                    self.revealed.toggle()
                }
            }
            
            if revealed == true {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Recent Events")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 5)
                    
                    DebugDeviceEventsList(deviceId: device.id)
                }
                .padding(.leading, 10)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DebugDeviceView: View {
    @Query(sort: \DevicesObject.addedOn) var devices: [DevicesObject]

    let layout = [GridItem(.flexible(minimum: 180, maximum: .infinity))]

    var body: some View {
        Text("Devices & Events").font(.title)

        if devices.isEmpty == true {
            Text("No devices detected. Ensure Bluetooth is enabled and devices are nearby.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical)
        }
        else {
            LazyVGrid(columns: layout, alignment: .leading, spacing:10) {
                ForEach(devices) { device in
                    if let appDevice = AppDeviceObject(device) {
                        DebugDeviceCell(appDevice)
                    }
                }

            }

        }

    }

}

struct DebugBroadcastCell: View {
    let device: BluetoothBroadcastItem
    @State var revealed: Bool
    
    init(_ device: BluetoothBroadcastItem, revealed: Bool = true) {
        self.device = device
        self._revealed = State(initialValue: revealed)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(device.peripheral.name ?? "Unknown Device")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(device.state.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut) {
                    self.revealed.toggle()
                }
            }
            
            if revealed == true {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Proximity:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(device.proximity.string ?? "Unknown")
                            .font(.caption)
                            .bold()
                    }
                    .padding(.leading, 5)
                    
                    if device.services.isEmpty == false {
                        Text("Services: \(device.services.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 5)
                            .padding(.top, 2)
                    }
                    
                    Text("ID: \(device.id.uuidString)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 5)
                        .lineLimit(1)
                }
                .padding(.leading, 10)
                .padding(.bottom, 5)
            }
        }
        .padding(.vertical, 4)
        .id(device.id)
    }
    
    var statusColor: Color {
        switch device.state {
        case .connected: return .green
        case .pending: return .yellow
        case .queued: return .orange
        case .disconnected: return .gray
        case .failed: return .red
        case .unavailable: return .red
        }
    }
}

struct DebugBroadcastView: View {
    @EnvironmentObject var bluetooth: BluetoothManager

    let layout = [GridItem(.flexible(minimum: 180, maximum: .infinity))]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Broadcasting")
                    .font(.title)
                
                Spacer()
                
                if bluetooth.proximity == .proximate {
                    Button("Wide Search") {
                        bluetooth.proximity = .far
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            .padding(.bottom, 5)
            
            LazyVGrid(columns: layout, alignment: .leading, spacing: 10) {
                if bluetooth.broadcasting.isEmpty == true {
                    Text("Searching for broadcasting devices...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical)
                }
                else {
                    ForEach(bluetooth.broadcasting) { device in
                        DebugBroadcastCell(device)
                    }
                }
            }
        }
    }
}

struct DebugContainer: View {
    @Query var devices: [DevicesObject]
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

                Text("Devices: \(devices.count)")

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
                
                Spacer()

                SettingContainer()
                
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
