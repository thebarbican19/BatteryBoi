//
//  MenuView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI
import Combine

enum BatteryViewType {
    case menubar
    case modal
    
}

enum BatteryAnimationType {
    case charging
    case percent
    case low

    var icon:String {
        switch self {
            case .percent : return ""
            case .charging : return "ChargingIcon"
            case .low : return "PlugIcon"
            
        }
        
    }
    
}

private struct BatteryMask: Shape {
    @Binding var radius:CGFloat

    init(_ radius: Binding<CGFloat>) {
        self._radius = radius
    }
    
    func path(in rect: CGRect) -> Path {
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

private struct BatteryCharge: View {
    @EnvironmentObject var manager:BatteryManager

    @State private var size:CGSize
    @State private var font:CGFloat
    @State private var animation:BatteryAnimationType = .charging
    @State private var timer:AnyCancellable? = nil

    init(_ size:CGSize, font:CGFloat) {
        self._size = State(initialValue: size)
        self._font = State(initialValue: font)

    }

    var body: some View {
        ZStack() {
            Image(self.animation.icon)
                .resizable()
                .padding(.vertical, 4)
                .aspectRatio(contentMode: .fit)
                .background(Color.clear)
                .scaleEffect(self.animation != .percent ? 1.0 : 0.8)
                .opacity(self.animation != .percent ? 1.0 : 0.0)
                .blur(radius: self.animation != .percent ? 0.0 : 2.0)
                .animation(Animation.default.delay(0.4), value: self.animation)

            Text(self.manager.formatted)
                .font(.system(size: self.font, weight: .bold))
                .lineLimit(1)
                .tracking(-0.4)
                .padding(2)
                .scaleEffect(self.animation == .percent ? 1.0 : 0.8)
                .opacity(self.animation == .percent ? 1.0 : 0.0)
                .animation(Animation.default.delay(0.4), value: self.animation)
            
        }
        .onAppear() {
            self.timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect().sink { _ in
                withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                    switch self.animation {
                        case .charging : self.animation = .percent
                        case .low : self.animation = .percent
                        case .percent : self.animation = self.manager.charging ? .charging : .low
                        
                    }
                    
                }

            }
            
            self.animation = self.manager.charging ? .charging : .low

        }
        .foregroundColor(Color.black)
        .frame(width: self.size.width, height: self.size.height)

    }
    
}

private struct BatteryStatus: View {
    @EnvironmentObject var manager:BatteryManager

    @State private var size:CGSize
    @State private var font:CGFloat
    
    init(_ size:CGSize, font:CGFloat) {
        self._size = State(initialValue: size)
        self._font = State(initialValue: font)

    }

    var body: some View {
        ZStack {
            if self.manager.charging || self.manager.percentage <= 25 {
                BatteryCharge(size, font: font)
                
            }
            else {
                Text(self.manager.formatted)
                    .font(.system(size: self.font, weight: .bold))
                    .frame(width: self.size.width, height: self.size.height)
                    .lineLimit(1)
                    .tracking(-0.4)
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
            BatteryMask(.constant(2)).foregroundColor(Color("BatteryDefault"))

            
        }
        .position(x:proxy.size.width + 1, y:proxy.size.height / 2)
        .frame(width: 1.5, height: 6)

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
        self._padding = State(initialValue: size.height > 30 ? 3 : 1.5)
        self._progress = State(initialValue: 1.0)

    }
    
    var body: some View {
        ZStack {
            HStack(alignment: .center) {
                Rectangle()
                    .frame(width: self.progress + 3, alignment: .leading)
                    .clipShape(BatteryMask($radius))
                
            }
            .frame(maxWidth: self.size.width, alignment: .leading)
            .foregroundColor(Color.black)
            .overlay(
                ZStack {
                    BatteryStatus(size, font: font).mask(
                        Rectangle()
                            .fill(.purple)
                            .position(x: (self.size.width / 2) + self.progress + 2, y: self.size.height / 2)
                            .offset(y:-2)

                    )

                }
                
            )
                        
        }
        .animation(.linear, value: self.manager.percentage)
        .clipShape(RoundedRectangle(cornerRadius: self.radius - self.padding, style: .continuous))
        .padding(self.padding)
        .onChange(of: self.manager.charging, perform: { newValue in
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                switch newValue {
                    case true : self.progress = min(100 * (self.size.width - 6), (self.size.width - 6))
                    case false : self.progress = min(CGFloat(self.manager.percentage / 100) * (self.size.width - 6), (self.size.width - 6))
                    
                }
                
            }
            
        })
        .onChange(of: self.manager.percentage, perform: { newValue in
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                switch self.manager.charging {
                    case true : self.progress = min(100 * (self.size.width - 6), (self.size.width - 6))
                    case false : self.progress = min(CGFloat(newValue / 100) * (self.size.width - 6), (self.size.width - 6))
                    
                }
                
            }
            
            if (self.max - 10) > 0 {
                self.radius = 10.0 + (1.0 - CGFloat(newValue / 100)) * (self.max - 10)

            }
            else {
                self.radius = 5.0 + (1.0 - CGFloat(newValue / 100))

            }
          
        })
        .onAppear() {
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                switch self.manager.charging {
                    case true : self.progress = min(100 * (self.size.width - 6), (self.size.width - 6))
                    case false : self.progress = min(CGFloat(self.manager.percentage / 100) * (self.size.width - 6), (self.size.width - 6))
                    
                }
                
            }
            
        }
        .inverse(
            BatteryStatus(size, font: font).mask(
                Rectangle()
                    .fill(.black)
                    .frame(width: self.size.width)
                    .position(x: -(self.size.width / 2) + self.progress + 6, y: self.size.height / 2)

            )
            
        )
        
    }
    
}

struct BatteryContainer: View {
    @EnvironmentObject var manager:BatteryManager

    @State private var size:CGSize
    @State private var radius:CGFloat
    @State private var font:CGFloat
    @State private var warning:Double = 0.0
    @State private var type:BatteryViewType

    init(_ size: CGSize, radius:CGFloat, font:CGFloat, type:BatteryViewType) {
        self._size = State(initialValue: size)
        self._radius = State(initialValue: radius)
        self._font = State(initialValue: font)
        self._type = State(initialValue: type)

    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: self.radius, style: .continuous)
                .fill(Color("BatteryDefault"))
                .frame(width:self.size.width, height: self.size.height)
                .mask(
                    Rectangle().inverse(BatteryIcon(size, radius: radius, font: font))
                    
                )
                

        }
        .overlay(
            GeometryReader { geo in
                BatteryStub(geo, size: .init(width: 4, height: size.height / 2))
                
            }
            
        )
        .onChange(of: self.manager.percentage) { newValue in
            self.warning = 20.0 - CGFloat(newValue / 20.0)
            
        }
        
    }
    
}

struct MenuContainer: View {
    var body: some View {
        BatteryContainer(.init(width: 32, height: 15), radius: 5, font: 11, type:.menubar)
            .opacity(0.9)
            .environmentObject(BatteryManager.shared)
        
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
