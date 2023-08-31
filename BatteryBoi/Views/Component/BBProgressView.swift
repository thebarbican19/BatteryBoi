//
//  BBProgressView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/15/23.
//

import SwiftUI

struct RadialProgressBar: View {
    @Binding var progress: Double
    
    @State public var size:CGSize
    
    @State private var rotation: Double = -65
    @State private var visible: Bool = false
    @State private var position: Double = 0.0

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: CGFloat(self.progress))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [Color(hexString: "E4FFD8"), Color.green, Color.green]), center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Circle()
                .fill(Color(hexString: "E4FFD8"))
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(Double(self.progress) * 360 - 90))
                .offset(y: -(size.height / 2))
                
        }
        .rotationEffect(.degrees(self.rotation))
        .frame(width: size.width, height: size.height, alignment: .center)
        .onAppear() {
            if self.visible == false {
                withAnimation(Animation.easeOut(duration: 0.6).delay(0.1)) {
                    self.rotation = 0.0
                    self.visible = true
                    self.position = self.progress
                    
                }
                
            }
            
        }
        
    }
    
}

struct RadialProgressContainer: View {
    @EnvironmentObject var manager:WindowManager
    @EnvironmentObject var battery:BatteryManager

    @State private var percent: Int = 100
    @State private var progress: Double = 0.0
    @State private var visible: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("BatterySubtitle").opacity(0.08), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .padding(5)
            
            RadialProgressBar(progress: $progress, size: .init(width: 80, height: 80))

            Text("\(self.percent)")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))

        }
        .offset(x:self.manager.state.content ? 0.0 : -34.0, y:self.manager.state.content ? 0.0 : -4.0)
        .frame(width: 90, height: 90)
        .onAppear() {
            if let device = AppManager.shared.device?.battery {
                if let min = [device.right, device.left, device.general].compactMap({ $0 }).min() {
                    self.progress = min / 100
                    self.percent = Int(min)

                }
                
            }
            else {
                self.percent = Int(self.battery.percentage)
                self.progress = self.battery.percentage / 100

            }
            
        }
        .onChange(of: self.battery.percentage) { newValue in
            if let device = AppManager.shared.device?.battery {
                if let min = [device.right, device.left, device.general].compactMap({ $0 }).min() {
                    self.progress = min / 100
                    self.percent = Int(min)

                }
                
            }
            else {
                self.percent = Int(self.battery.percentage)
                self.progress = self.battery.percentage / 100

            }

        }

    }
    
}

