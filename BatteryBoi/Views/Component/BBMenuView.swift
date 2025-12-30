//
//  MenuView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI
import Combine
import DynamicColor

public struct BatteryPulsatingIcon: View {
    @EnvironmentObject var manager:BatteryManager
    @EnvironmentObject var menubar:MenubarManager

    @State private var animate:Bool = false
    @State private var visible:Bool = false
    @State private var icon:String = "ChargingIcon"
    
    init(_ icon:String) {
        self._icon = State(initialValue: icon)

    }
    
    public var body: some View {
        Rectangle()
            .fill(menubar.style.text)
            .mask(
               Image(icon)
                   .resizable()
                   .aspectRatio(contentMode: .fit)
            
            )
            .frame(width: menubar.style.icon.width, height: menubar.style.icon.height)
            .onAppear() {
                withAnimation(Animation.easeInOut) {
                    self.visible = true
                    
                }
            }
            .offset(y:0.4)
            .opacity(self.visible ? 1.0 : 0.0)
            .onChange(of: self.visible) { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + (self.visible ? 2.0 : 0.8)) {
                    if self.menubar.animation == true {
                        withAnimation(Animation.easeInOut) {
                            self.visible.toggle()
                            
                        }
                        
                    }
    
                }
    
            }
            .onChange(of: self.menubar.animation) { newValue in
                withAnimation(Animation.easeInOut) {
                    switch newValue {
                        case true : self.visible.toggle()
                        case false : self.visible = true
                        
                    }
                    
                }
                
            }
        
        
    }
    
}




public struct BatteryMask: Shape {
    private var radius:CGFloat

    init(_ value: CGFloat) {
        self.radius = value
        
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width - self.radius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: self.radius), control: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - self.radius))
        path.addQuadCurve(to: CGPoint(x: rect.width - self.radius, y: rect.height), control: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))

        return path
        
    }
    
}

private struct BatteryStatus: View {
    @EnvironmentObject var manager:BatteryManager
    @EnvironmentObject var menubar:MenubarManager

    @State private var icon:String? = nil

    @Binding private var hover:Bool
    
    init(hover:Binding<Bool>) {
        self._hover = hover
        
    }

    var body: some View {
        ZStack {
            if let overlay = menubar.seconary {
                Text(overlay)
                    .style(menubar.style.font, kerning:menubar.style.kerning)
                    .offset(y:self.hover ? 0.0 : -menubar.style.size.height)
                
            }

            HStack(alignment: .center, spacing:menubar.style.spacing) {
                if let icon = self.icon {
                    BatteryPulsatingIcon(icon)
                    
                }
                
                if let summary = menubar.primary {
                    Text(summary)
                        .style(menubar.style.font, kerning:menubar.style.kerning)
                    
                }
                
            }
            .offset(y:self.hover ? menubar.style.size.height : 0.0)
            .frame(width: menubar.style.size.width, height: self.menubar.style.size.height)
            
        }
        .onAppear() {
            if self.manager.charging == .charging && self.manager.percentage != 100 {
                self.icon = "ChargingIcon"
                
            }
            else {
                self.icon = nil

            }
            
        }
        .onChange(of: manager.charging) { newValue in
            if newValue == .charging && self.manager.percentage != 100 {
                self.icon = "ChargingIcon"
                
            }
            else {
                self.icon = nil

            }
            
        }
        .onChange(of: manager.percentage) { newValue in
            if self.manager.charging == .charging && newValue != 100 {
                self.icon = "ChargingIcon"

            }
            else {
                self.icon = nil

            }
            
        }
        .onChange(of: manager.thermal.state) { newValue in
            if newValue == .suboptimal {
                self.icon = "OverheatIcon"

            }
            else {
                self.icon = nil

            }
            
        }
        .frame(alignment: .center)
        .foregroundColor(menubar.style.text)
        .animation(Animation.easeInOut, value: manager.charging)

    }
    
}

private struct BatteryStub: View {
    @EnvironmentObject var menubar:MenubarManager

    let proxy:GeometryProxy

    init(_ proxy: GeometryProxy) {
        self.proxy = proxy
        
    }
    
    var body: some View {
        ZStack {
            BatteryMask(3.4).foregroundColor(Color("BatteryDefault"))

        }
        .position(x:proxy.size.width + 2, y:proxy.size.height / 2)
        .frame(width: 1.6, height: 6)
        .opacity(menubar.style.stub)

    }
    
}

struct BatteryIcon: View {
    @EnvironmentObject var manager:BatteryManager
    @EnvironmentObject var menubar:MenubarManager

    @State var progress:CGFloat
    
    @Binding var hover:Bool

    init(hover:Binding<Bool>) {
        self._progress = State(initialValue: 1.0)
        self._hover = hover

    }
    
    var body: some View {
        ZStack {
            HStack(alignment: .center) {
                Rectangle()
                    .frame(width: self.progress, alignment: .leading)
                    .clipShape(BatteryMask(menubar.radius))
    
            }
            .frame(maxWidth: menubar.style.size.width, alignment: .leading)
            .foregroundColor(Color.black)
            .overlay(
                BatteryStatus(hover: $hover)
             
            )
                        
        }
        .animation(.linear, value: self.manager.percentage)
        .inverse(
            BatteryStatus(hover: $hover).mask(
                Rectangle()
                    .fill(.black)
                    .frame(width: menubar.style.size.width)
                    .position(x: -(menubar.style.size.width / 2) + (self.progress + menubar.style.padding), y: menubar.style.size.height / 2)
                
                
                
            )
                    
            
        )
        .clipShape(RoundedRectangle(cornerRadius: menubar.radius - menubar.style.padding, style: .continuous))
        .padding(menubar.style.padding)
        .onChange(of: self.manager.charging, perform: { newValue in
            self.update(self.manager.percentage)

        })
        .onChange(of: self.manager.percentage, perform: { newValue in
            self.update(newValue)
          
        })
        .onChange(of: self.menubar.progress, perform: { newValue in
            self.update(self.manager.percentage)

        })
        .onAppear() {
            self.update(self.manager.percentage)

        }
        
    }
    
    private func update(_ percentage:Int) {
        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
            if BatteryManager.shared.charging == .battery {
                switch MenubarManager.shared.progress {
                    case .progress : self.progress = self.manager.charging.progress(self.manager.percentage, width: menubar.style.size.width)
                    case .empty : self.progress = self.manager.charging.progress(100, width: menubar.style.size.width)
                    case .full : self.progress = self.manager.charging.progress(0, width: menubar.style.size.width)
                    
                }
                
            }
            else {
                switch MenubarManager.shared.progress {
                    case .empty : self.progress = self.manager.charging.progress(100, width: menubar.style.size.width)
                    default : self.progress = self.manager.charging.progress(0, width: menubar.style.size.width)
                    
                }
                
            }
            
        }
        
    }
    
}

struct BatteryEmpty: View {
    @EnvironmentObject var menubar:MenubarManager
    @EnvironmentObject var manager:BatteryManager

    @Binding var hover:Bool

    @State private var color:Color = Color("BatteryDefault")
    @State private var standard:Color = Color("BatteryDefault")

    let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    
    init(hover:Binding<Bool>) {
        self._hover = hover

    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            BatteryStatus(hover: $hover)

        }
        .mask(
            RoundedRectangle(cornerRadius: self.menubar.radius, style: .continuous)
                .frame(width:self.menubar.style.size.width, height: self.menubar.style.size.height)

        )
        .onReceive(timer) { _ in
            withAnimation(Animation.easeInOut(duration: 0.75)) {
                if manager.percentage <= 25 && manager.charging == .battery {
                    switch color {
                        case standard : color = menubar.scheme.warning
                        default : color = standard
                        
                    }
                    
                }
                
            }
            
        }
        .animation(.easeIn, value: menubar.style)
        
    }
    
}


struct BatteryTransparent: View {
    @EnvironmentObject var menubar:MenubarManager
    @EnvironmentObject var manager:BatteryManager

    @State private var color:Color = Color("BatteryDefault")
    @State private var standard:Color = Color("BatteryDefault")

    @Binding var hover:Bool

    let timer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    init(hover:Binding<Bool>) {
        self._hover = hover

    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: menubar.radius, style: .continuous)
                .fill(Color("BatteryDefault"))
                .opacity(menubar.style.background)
                .frame(width:menubar.style.size.width, height: menubar.style.size.height)
                
            RoundedRectangle(cornerRadius: menubar.radius, style: .continuous)
                .fill(color)
                .opacity(menubar.style.foreground)
                .frame(width:(menubar.style.size.width / CGFloat(manager.max)) * CGFloat(manager.percentage), height: menubar.style.size.height)
            
        }
        .mask(
            RoundedRectangle(cornerRadius: menubar.radius, style: .continuous)
                .frame(width:menubar.style.size.width, height: menubar.style.size.height)
                .inverse(BatteryStatus(hover: $hover))
            
        )
        .onReceive(timer) { _ in
            withAnimation(Animation.easeInOut(duration: 0.75)) {
                if manager.percentage <= 25 && manager.charging == .battery {
                    switch color {
                        case standard : color = menubar.scheme.warning
                        default : color = standard
                        
                    }
                    
                }
                else if manager.mode == .efficient {
                    switch color {
                        case standard : color = menubar.scheme.efficient
                        default : color = standard
                        
                    }
                    
                }
                else {
                    color = standard
                    
                }
                
            }
            
        }
        .animation(Animation.easeInOut, value: menubar.style)
        
    }
    
}

struct BatteryOriginal: View {
    @EnvironmentObject var menubar:MenubarManager

    @Binding var hover:Bool

    init(hover:Binding<Bool>) {
        self._hover = hover

    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: menubar.radius, style: .continuous)
            .fill(Color("BatteryDefault"))
            .opacity(0.9)
            .frame(width:menubar.style.size.width, height: menubar.style.size.height)
            .animation(.easeInOut, value: menubar.style)
            .mask(
                Rectangle().inverse(BatteryIcon(hover: $hover))
                
            )
        
    }
    
}


struct BatteryContainer: View {
    @EnvironmentObject var manager:BatteryManager
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var menubar:MenubarManager

    @State private var hover:Bool = false

    var body: some View {
        ZStack {
            switch menubar.style {
                case .original : BatteryOriginal(hover: $hover)
                case .transparent : BatteryTransparent(hover: $hover)
                case .text : BatteryEmpty(hover: $hover)

            }
            
        }
        .animation(.easeIn, value: menubar.style)
        .onHover { hover in
            if menubar.seconary != nil {
                withAnimation(Animation.easeOut(duration: 0.3).delay(self.hover ? 0.8 : 0.1)) {
                    self.hover = hover
                    
                }
                
            }
            
        }
        .onChange(of: self.manager.charging, perform: { newValue in
            if newValue == .charging && self.hover == true {
                withAnimation(Animation.easeOut(duration: 0.3)) {
                    self.hover = false
                    
                }
            
            }
            
        })
        .overlay(
            GeometryReader { geo in
                if let _ = self.updates.available {
                    Circle()
                        .fill(Color("BatteryEfficient"))
                        .frame(width: 5, height: 5)
                        .position(x:-5, y: (geo.size.height / 2) + 0.5)
                    
                }
                
                BatteryStub(geo)
                
            }
            
        )
        
    }
    
}

struct MenuContainer: View {
    var body: some View {
        BatteryContainer()
            .environmentObject(BatteryManager.shared)
            .environmentObject(StatsManager.shared)
            .environmentObject(UpdateManager.shared)
            .environmentObject(CloudManager.shared)
            .environmentObject(BluetoothManager.shared)
            .environmentObject(ProcessManager.shared)
            .environmentObject(MenubarManager.shared)

    }
    
}

struct MenuViewRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> NSHostingView<MenuContainer> {
        let hostingView = NSHostingView(rootView: MenuContainer())
        hostingView.frame.size = NSSize(width: 100, height: 20)
        return hostingView
        
    }

    func updateNSView(_ nsView: NSHostingView<MenuContainer>, context: Context) {

    }
    
}
