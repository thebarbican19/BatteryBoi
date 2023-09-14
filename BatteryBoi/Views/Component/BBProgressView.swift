//
//  BBProgressView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/15/23.
//

import SwiftUI

struct RadialProgressBar: View {
    @Binding var progress: Double
    
    @State private var size:CGSize
    @State private var line:CGFloat
    @State private var monochrome:Bool
    @State private var position: Double = 0.0
    
    init(_ progress:Binding<Double>, size:CGSize, line:CGFloat = 10, monochrome:Bool = false) {
        self._progress = progress
        self._size = State(initialValue: size)
        self._line = State(initialValue: line)
        self._monochrome = State(initialValue: monochrome)

    }
    
    var body: some View {
        ZStack {
            if self.monochrome == true {
                Circle()
                    .trim(from: 0.0, to: CGFloat(self.progress))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [Color("BatteryTitle"), Color("BatteryTitle").opacity(0.96)]), center: .center),
                        style: StrokeStyle(lineWidth: self.line, lineCap: .round)
                
                    )
                    .rotationEffect(.degrees(-90))
              
                
            }
            else {
                Circle()
                    .trim(from: 0.0, to: CGFloat(self.progress))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [Color(hexString: "E4FFD8"), Color.green, Color.green]), center: .center),
                        style: StrokeStyle(lineWidth: self.line, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
            }
            
            Circle()
                .fill(self.monochrome ? Color("BatteryTitle") : Color(hexString: "E4FFD8"))
                .frame(width: self.line, height: self.line)
                .rotationEffect(.degrees(Double(self.progress) * 360 - 90))
                .offset(y: -(size.height / 2))
                
        }
        .frame(width: size.width, height: size.height, alignment: .center)
        .onAppear() {
            withAnimation(Animation.easeOut(duration: 0.6).delay(0.1)) {
                self.position = self.progress
                
            }
            
        }
        
    }
    
}

struct RadialProgressMiniContainer: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var bluetooth:BluetoothManager

    @State private var device:BluetoothObject?
    @State private var progress: Double = 0.0
    @State private var percent: Int = 100
    
    init(_ device:BluetoothObject?) {
        self._device = State(initialValue: device)
        
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color("BatterySubtitle").opacity(0.08), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            
            RadialProgressBar($progress, size: .init(width: 28, height: 28), line: 4, monochrome: true)
            
            VStack {
                Text("\(self.percent)")
                    .foregroundColor(Color("BatteryTitle"))
                    .font(.system(size: 10, weight: .medium))
                
            }

        }
        .frame(width: 28, height: 28)
        .onAppear() {
            if let battery = self.device?.battery {
                if let percent = battery.percent {
                    self.progress = percent / 100
                    self.percent = Int(percent)
                    
                }
                
            }
            
        }
        .onChange(of: self.bluetooth.list.first(where: { $0.address == device?.address })) { device in
            if let battery = device?.battery {
                if let percent = battery.percent {
                    self.progress = percent / 100
                    self.percent = Int(percent)
                    
                }
                
            }
            
        }
        
    }
    
}

struct RadialProgressContainer: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var window:WindowManager
    @EnvironmentObject var battery:BatteryManager

    @State private var percent: Int? = nil
    @State private var progress: Double = 0.0
    @State private var animate: Bool

    init(_ animate:Bool) {
        self._animate = State(initialValue: animate)
        
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("BatterySubtitle").opacity(0.08), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .padding(5)
            
            RadialProgressBar($progress, size: .init(width: 80, height: 80))

            if let percentage = self.percent {
                VStack {
                    Text("\(percentage)")
                        .foregroundColor(Color("BatteryTitle"))
                        .font(.system(size: 20, weight: .bold))
                    
                }
                
            }

        }
        .frame(width: 90, height: 90)
        .padding(10)
        .onAppear() {
            withAnimation(Animation.easeOut(duration: self.animate ? 1.2 : 0.0)) {
                if let percent = self.manager.device?.battery.percent {
                    self.progress = percent / 100
                    
                }
                else {
                    self.progress = self.battery.percentage / 100
                    
                }
                
            }
            
            withAnimation(Animation.easeOut(duration: 0.1).delay(self.animate ? 0.2 : 0.0)) {
                if let percent = self.manager.device?.battery.percent {
                    self.percent = Int(percent)
                    
                }
                else {
                    self.percent = Int(self.battery.percentage)
                    
                }
                
            }
            
        }
        .onChange(of: self.battery.percentage) { newValue in
            if let percent = self.manager.device?.battery.percent {
                self.progress = percent / 100
                self.percent = Int(percent)

            }
            else {
                self.percent = Int(self.battery.percentage)
                self.progress = self.battery.percentage / 100

            }

        }
        .onChange(of: self.manager.device) { device in
            if let percent = device?.battery.percent {
                self.progress = percent / 100
                self.percent = Int(percent)

            }
            else {
                self.percent = Int(self.battery.percentage)
                self.progress = self.battery.percentage / 100

            }
            
        }

    }
    
}

