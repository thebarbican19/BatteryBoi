//
//  MenuView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI
import Combine

enum BatteryStyle:String {
    case chunky
    case basic
    
    var radius:CGFloat {
        switch self {
            case .basic : return 3
            case .chunky : return 5
            
        }
        
    }
    
    var size:CGSize {
        switch self {
            case .basic : return .init(width: 28, height: 13)
            case .chunky : return .init(width: 32, height: 15)
            
        }
        
    }
    
    var padding:CGFloat {
        switch self {
            case .basic : return 1
            case .chunky : return 2
            
        }
        
    }
    
}

enum BatteryAnimationType {
    case charging
    case low
    
}

public struct BatteryPulsatingIcon: View {
    @EnvironmentObject var manager:BatteryManager

    @State private var visible:Bool = false
    @State private var icon:String? = "ChargingIcon"
    
    public var body: some View {
        VStack {
            if let icon = self.icon {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .font(.system(size: 20, weight: .bold))
                    .opacity(self.visible ? 1.0 : 0.0)
                    .background(Color.clear)
                    .foregroundColor(Color.white)
                    .padding(2)
                    .offset(y:0)
                    .onAppear() {
                        withAnimation(Animation.easeInOut) {
                            self.visible.toggle()
                            
                        }
                        
                    }
            }
            
        }
        .onAppear() {
            if manager.charging.state == .charging && manager.percentage != 100 {
                self.icon = "ChargingIcon"
                
            }
            else {
                self.icon = nil
                
            }
            
        }
        .onChange(of: manager.charging) { newValue in
            if newValue.state == .charging {
                self.icon = "ChargingIcon"
                
            }
            else {
                self.icon = nil
                
            }
            
        }
        .onChange(of: self.visible) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + (self.visible ? 2.0 : 0.8)) {
                withAnimation(Animation.easeInOut) {
                    self.visible.toggle()
                    
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
    @EnvironmentObject var stats:StatsManager

    @State private var size:CGSize
    @State private var font:CGFloat
    
    init(_ size:CGSize, font:CGFloat) {
        self._size = State(initialValue: size)
        self._font = State(initialValue: font)

    }

    var body: some View {
        HStack(spacing: 0.5) {
            if self.manager.charging.state == .charging || self.manager.percentage <= 25 {
                BatteryPulsatingIcon()

            }

            if let summary = self.stats.display {
                Text(summary)
                    .frame(width: self.size.width, height: self.size.height)
                    .style(self.font)
                    .padding(2)
                    .foregroundColor(Color.black)
                                
            }
            
        }
        .animation(Animation.easeInOut, value: self.manager.charging)

    }
    
}

private struct BatteryStub: View {
    @State private var proxy:GeometryProxy
    @State private var size:CGSize

    init(_ proxy: GeometryProxy, size:CGSize) {
        self._proxy = State(initialValue: proxy)
        self._size = State(initialValue: size)
        
    }
    
    var body: some View {
        ZStack {
            BatteryMask(3.4).foregroundColor(Color("BatteryDefault"))

        }
        .position(x:proxy.size.width + 2, y:proxy.size.height / 2)
        .frame(width: 1.6, height: 6)
        .opacity(0.6)

    }
    
}

struct BatteryIcon: View {
    @EnvironmentObject var manager:BatteryManager
    
    @State var size:CGSize
    @State var radius:CGFloat = 25
    @State var max:CGFloat = 25
    @State var font:CGFloat
    @State var padding:CGFloat
    @State var progress:CGFloat

    init(_ size: CGSize, radius: CGFloat, font:CGFloat) {
        self._size = State(initialValue: size)
        self._radius = State(initialValue: radius)
        self._max = State(initialValue: radius)
        self._font = State(initialValue: font)
        self._padding = State(initialValue: 1.6)
        self._progress = State(initialValue: 1.0)

    }
    
    var body: some View {
        ZStack {
            HStack(alignment: .center) {
                Rectangle()
                    .frame(width: self.progress, alignment: .leading)
                    .clipShape(BatteryMask(3.4))
    
            }
            .frame(maxWidth: self.size.width, alignment: .leading)
            .foregroundColor(Color.black)
            .overlay(
                BatteryStatus(size, font: font).mask(
                    Rectangle()
                        .fill(.black)
                        .position(x: self.progress, y: self.size.height / 2)
                        .offset(y:-2)

                )
             
            )
                        
        }
        .animation(.linear, value: self.manager.percentage)
        .inverse(
            BatteryStatus(size, font: font).mask(
                Rectangle()
                    .fill(.black)
                    .frame(width: self.size.width)
                    .position(x: -(self.size.width / 2) + (self.progress + 2.6), y: self.size.height / 2)

            )
            
        )
        .clipShape(RoundedRectangle(cornerRadius: self.radius - self.padding, style: .continuous))
        .padding(self.padding)
        .onChange(of: self.manager.charging.state, perform: { newValue in
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                self.progress = newValue.progress(self.manager.percentage, width: self.size.width)
                
            }
            
        })
        .onChange(of: self.manager.percentage, perform: { newValue in
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                self.progress = self.manager.charging.state.progress(newValue, width: self.size.width)
                
            }
          
        })
        .onAppear() {
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                self.progress = self.manager.charging.state.progress(self.manager.percentage, width: self.size.width)
                
            }
            
        }
       

    }
    
}

struct BatteryContainer: View {
    @EnvironmentObject var manager:BatteryManager
    @EnvironmentObject var updates:UpdateManager

    @State private var size:CGSize
    @State private var radius:CGFloat
    @State private var font:CGFloat

    init(_ size: CGSize, radius:CGFloat, font:CGFloat) {
        self._size = State(initialValue: size)
        self._radius = State(initialValue: radius)
        self._font = State(initialValue: font)

    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: self.radius, style: .continuous)
                .fill(Color("BatteryDefault"))
                .opacity(0.9)
                .frame(width:self.size.width, height: self.size.height)
                .mask(
                    Rectangle().inverse(BatteryIcon(size, radius: radius, font: font))
                    
                )

        }
        .overlay(
            GeometryReader { geo in
                if let _ = self.updates.available {
                    Circle()
                        .fill(Color("BatteryEfficient"))
                        .frame(width: 5, height: 5)
                        .position(x:-5, y: (geo.size.height / 2) + 0.5)
                    
                }
                
                BatteryStub(geo, size: .init(width: 4, height: size.height / 2))
                
            }
            
        )
        
    }
    
}

struct MenuContainer: View {
    var body: some View {
        BatteryContainer(.init(width: 32, height: 15), radius: 5, font: 11)
            .environmentObject(BatteryManager.shared)
            .environmentObject(StatsManager.shared)

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
