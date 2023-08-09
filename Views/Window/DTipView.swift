//
//  TipView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI
import DynamicColor
import FluidGradient

struct TipContainer: View {
    @EnvironmentObject var manager:BatteryManager

    @State var progress:Float = 1.0

    var body: some View {
        VStack {
            ZStack {
                FluidGradient(blobs: [Color(hexString:"3a8edfd"), Color(hexString:"#f0f2fe"), Color(hexString:"#bdbeff")], highlights: [Color(hexString:"#9ba3ff"), Color(hexString:"#91e3ff")], speed: 0.4, blur: 0.7)
                    .blur(radius: 5)
                    .blendMode(.overlay)
            
                BatteryContainer(.init(width: 150, height: 55), radius: 16, font: 18, type: .modal)
                    .environmentObject(BatteryManager.shared)
                
            }
           
            Slider(value: $progress).padding(.top, 70).onChange(of: progress, perform: { newValue in
                self.manager.percentage = newValue * 100
                
            })
            
        }
        
    }
    
}

struct TipView: View {
    var screen = NSScreen.main!.visibleFrame
    var body: some View {
        VStack {
            TipContainer()
            
        }
        .offset(x: 0, y: -60)
        .ignoresSafeArea(.all, edges: .all)
        .frame(maxWidth: screen.width, maxHeight: screen.height + 60)
        .background(Color(hexString: "#262335"))
        .background(WindowViewBlur())
        .environmentObject(BatteryManager.shared)
        
    }
    
}
