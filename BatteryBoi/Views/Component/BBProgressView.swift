//
//  BBProgressView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/15/23.
//

import SwiftUI
import DynamicColor

enum RadialStyle {
    case dark
    case light
    case colour
    
    var background:Color {
        switch self {
            case .dark : return Color("BatteryTitle")
            case .light : return Color("BatteryDefault")
            case .colour : return Color(hexString: "E4FFD8")
            
        }
        
    }
    
}

struct RadialProgressBar: View {
    @Binding var progress: Double
    
    @State private var size:CGSize
    @State private var line:CGFloat
    @State private var position: Double = 0.0
    
    @Binding var style:RadialStyle

    init(_ progress:Binding<Double>, size:CGSize, line:CGFloat = 10, style:Binding<RadialStyle>) {
        self._progress = progress
        self._size = State(initialValue: size)
        self._line = State(initialValue: line)
        
        self._style = style

    }
    
    var body: some View {
        ZStack {
            if self.style == .dark {
                Circle()
                    .trim(from: 0.0, to: CGFloat(self.position))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [Color("BatteryTitle"), Color("BatteryTitle").opacity(0.96)]), center: .center),
                        style: StrokeStyle(lineWidth: self.line, lineCap: .round)
                
                    )
                    .rotationEffect(.degrees(-90))
              
                
            }
            else if self.style == .light {
                Circle()
                    .trim(from: 0.0, to: CGFloat(self.position))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [Color("BatteryButton"), Color("BatteryButton").opacity(0.96)]), center: .center),
                        style: StrokeStyle(lineWidth: self.line, lineCap: .round)
                
                    )
                    .rotationEffect(.degrees(-90))
              
                
            }
            else {
                Circle()
                    .trim(from: 0.0, to: CGFloat(self.position))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [Color(hexString: "E4FFD8"), Color.green, Color.green]), center: .center),
                        style: StrokeStyle(lineWidth: self.line, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
            }
          
            Circle()
                .fill(self.style.background)
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
        .onChange(of: self.progress) { newValue in
            withAnimation(Animation.easeOut(duration: 0.6)) {
                self.position = self.progress
                
            }
            
        }
        
    }
    
}

struct RadialProgressMiniContainer: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var bluetooth:BluetoothManager
    @EnvironmentObject var battery:BatteryManager

    @State private var device:BluetoothObject?
    @State private var progress: Double = 0.0
    @State private var percent: Int = 100
    
    @Binding private var style:RadialStyle

    init(_ device:BluetoothObject?, style:Binding<RadialStyle>) {
        self._device = State(initialValue: device)
        self._style = style
        
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color("BatterySubtitle").opacity(0.08), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            
            RadialProgressBar($progress, size: .init(width: 28, height: 28), line: 4, style: $style)
            
            VStack {
                Text("\(self.percent)")
                    .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatteryTitle"))
                    .font(.system(size: 10, weight: .medium))
                
            }

        }
        .frame(width: 28, height: 28)
        .onAppear() {
            if let device = self.device {
                if let percent = device.battery.percent {
                    self.progress = percent / 100
                    self.percent = Int(percent)
                    
                }
                
            }
            else {
                self.percent = Int(self.battery.percentage)
                self.progress = self.battery.percentage / 100
                
            }
            
        }
        .onChange(of: self.bluetooth.list.first(where: { $0.address == device?.address })) { device in
            if let battery = device?.battery {
                if let percent = battery.percent {
                    self.progress = percent / 100
                    self.percent = Int(percent)
                    
                }
                
            }
            else {
                self.percent = Int(self.battery.percentage)
                self.progress = self.battery.percentage / 100
                
            }
            
        }
        
    }
    
}

struct RadialProgressContainer: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var window:WindowManager
    @EnvironmentObject var battery:BatteryManager

    @State private var percent:Int? = nil
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
            
            RadialProgressBar($progress, size: .init(width: 80, height: 80), style: .constant(.colour))

            ZStack(alignment: .center) {
                Text("\(self.percent ?? 0)")
                    .foregroundColor(Color("BatteryTitle"))
                    .font(.system(size: 20, weight: .bold))
                    .blur(radius: self.percent == nil ? 5.0 : 0.0)
                    .opacity(self.percent == nil ? 0.0 : 1.0)

                Text("N/A")
                    .foregroundColor(Color("BatteryTitle").opacity(0.4))
                    .font(.system(size: 14, weight: .bold))
                    .blur(radius: self.percent == nil ? 0.0 : 5.0)
                    .opacity(self.percent == nil ? 1.0 : 0.0)

            }
            .frame(width: 90)

        }
        .frame(width: 90, height: 90)
        .padding(10)
        .onAppear() {
            withAnimation(Animation.easeOut(duration: self.animate ? 1.2 : 0.0)) {
                if let device = manager.device {
//                    if let percent = device.battery.percent {
//                        self.progress = percent / 100
//                        self.percent = Int(percent)
//
//                    }
//                    else {
//                        self.progress = 0.0
//                        self.percent = nil
//                    }
                    
                }
                else {
                    self.progress = self.battery.percentage / 100
                    self.percent = Int(self.battery.percentage)

                }
            
            }
            
        }
        .onChange(of: self.battery.percentage) { newValue in
//            if let percent = self.manager.device?.battery.percent {
//                self.progress = percent / 100
//                self.percent = Int(percent)
//
//            }
//            else {
//                self.percent = Int(self.battery.percentage)
//                self.progress = self.battery.percentage / 100
//
//            }

        }
//        .onChange(of: self.manager.device) { device in
//            withAnimation(Animation.easeOut(duration: 0.4)) {
//                if let device = manager.device {
//                    if let percent = device.battery.percent {
//                        self.progress = percent / 100
//                        self.percent = Int(percent)
//
//                    }
//                    else {
//                        self.progress = 0.0
//                        self.percent = nil
//                    }
//                    
//                }
//                else {
//                    self.progress = self.battery.percentage / 100
//                    self.percent = Int(self.battery.percentage)
//
//                }
//            
//            }
//            
//        }

    }
    
}

