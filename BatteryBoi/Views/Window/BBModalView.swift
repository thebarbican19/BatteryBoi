//
//  JModalView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/10/23.
//

import SwiftUI
import DynamicColor
import Combine

enum ModalAnimationTypes:Int {
    case initial
    case begin
    case pinhole
    case reveal
    case stats
    case detailed
    case settings
    case dismiss
    
    var blur:CGFloat {
        switch self {
            case .initial : return 12
            case .begin : return 12.0
            case .pinhole : return 2.0
            case .reveal : return 0.0
            case .detailed : return 0.0
            case .settings : return 0.0
            case .stats : return 0.0
            case .dismiss : return 4.0

        }
        
    }
    
    var opacity:Double {
        switch self {
            case .initial : return 0.05
            case .begin : return 0.05
            case .pinhole : return 1.0
            case .reveal : return 1.0
            case .detailed : return 1.0
            case .settings : return 1.0
            case .stats : return 1.0
            case .dismiss : return 0.0

        }
        
    }
    
    var size:CGSize {
        switch self {
            case .initial : return .init(width: 240, height: 240)
            case .begin : return .init(width: 40, height: 40)
            case .pinhole : return .init(width: 120, height: 120)
            case .reveal : return .init(width: 400, height: 120)
            case .detailed : return .init(width: 410, height: 220)
            case .stats : return .init(width: 410, height: 260)
            case .settings : return .init(width: 410, height: 390)
            case .dismiss : return .init(width: 120, height: 120)
    
        }
        
    }
    
    var duration:CGFloat {
        switch self {
            case .initial : return 0.01
            case .begin : return 1.4
            case .pinhole : return 0.5
            case .reveal : return 0.5
            case .detailed : return 3.0
            case .settings : return 3.0
            case .stats : return 3.0
            case .dismiss : return 0.05

        }
        
    }
    
    func automatic(_ modal:ModalAlertTypes) -> Bool {
        switch self {
            case .initial : return false
            case .begin : return true
            case .pinhole : return true
            case .reveal : return true
            case .detailed : return modal == .userInitiated ? true : false
            case .settings : return false
            case .stats : return false
            case .dismiss : return false

        }
        
    }
    
    var radius:CGFloat {
        switch self {
            case .initial : return 66
            case .begin : return 66
            case .pinhole : return 66
            case .reveal : return 66
            case .detailed : return 42
            case .settings : return 42
            case .stats : return 42
            case .dismiss : return 66

        }
        
    }
    
    var bounce:CGFloat {
        switch self {
            case .initial : return 0.0
            case .begin : return 0.0
            case .pinhole : return 0.0
            case .reveal : return 8.0
            case .detailed : return 0.0
            case .settings : return 0.0
            case .stats : return 0.0
            case .dismiss : return 0.0

        }
        
    }
    
    var scale:CGFloat {
        switch self {
            case .dismiss : return 0.8
            default : return 1.0

        }
        
    }
    
    var content:Bool {
        switch self {
            case .initial : return false
            case .begin : return false
            case .pinhole : return false
            case .reveal : return true
            case .detailed : return true
            case .settings : return true
            case .stats : return true
            case .dismiss : return false

        }
        
    }
    
    var expanded:Bool {
        switch self {
            case .initial : return false
            case .begin : return false
            case .pinhole : return false
            case .reveal : return false
            case .detailed : return true
            case .settings : return true
            case .stats : return true
            case .dismiss : return false
            
        }
        
    }
    
}

enum ModalAlertTypes:Int {
    case chargingComplete
    case chargingBegan
    case chargingStopped
    case percentFive
    case percentTen
    case percentTwentyFive
    case percentOne
    case userInitiated
    case userLaunched
    case deviceConnected
    case deviceRemoved
    case deviceDistance

    var sfx:SystemSoundEffects? {
        switch self {
            case .chargingBegan : return .high
            case .chargingComplete : return .high
            case .chargingStopped : return .low
            case .percentTwentyFive : return .low
            case .percentTen : return .low
            case .percentFive : return .low
            case .percentOne : return .low
            case .userLaunched : return nil
            case .userInitiated : return nil
            case .deviceRemoved : return .low
            case .deviceConnected : return .high
            case .deviceDistance : return .low

        }
        
    }
    
    var trigger:Bool {
        switch self {
            case .chargingBegan : return true
            case .chargingComplete : return true
            case .chargingStopped : return true
            case .deviceRemoved : return true
            case .deviceConnected : return true
            default : return false
            
        }
        
    }

}

struct ModalMenuView: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var settings:SettingsManager
    @EnvironmentObject var bluetooth:BluetoothManager

    @State var update:Bool = false
    @State var hover:Bool = false
    @State var scroll:CGPoint = .zero
    @State var size:CGSize = .zero

    var body: some View {
        ZStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(settings.menu, id: \.self) { item in
                                if self.manager.menu == .settings {
                                    SettingsItem(hover:$hover, item: item)
                                    
                                }
                                
                            }
                            
                            ForEach(bluetooth.list, id: \.address) { item in
                                if self.manager.menu == .devices {
                                    BluetoothItem(hover:$hover, item: item)
                                    
                                }
                                
                            }
                            
                            Spacer().frame(width: size.width)
                            
                        }
                        .animation(Animation.bouncy, value: self.manager.menu)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: SettingsScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).origin)
                            
                        })
                        .onPreferenceChange(SettingsScrollOffsetKey.self) { value in
                            if WindowManager.shared.state == .detailed {
                                self.scroll = value
                                
                            }
                            
                        }
                        
                    }
                    .coordinateSpace(name: "scroll")
                    .mask(30, scroll: $scroll)
                    .frame(width: geo.size.width)

                    ZStack(alignment: .trailing) {
                        HStack(spacing:8) {
                            SettingsOverlayItem(.appDevices)
                                .opacity(self.bluetooth.connected.count > 0 ? 1.0 : 0.0)
                                .scaleEffect(self.bluetooth.connected.count > 0 ? 1.0 : 0.8)
                            
                            SettingsOverlayItem(.appQuit)
                            
                        }
                        
                    }
                    .frame(height:60)
                    .background(
                        HStack(alignment: .center, spacing: 0) {
                            LinearGradient(gradient: Gradient(colors: [Color("BatteryBackground").opacity(0.0), Color("BatteryBackground")]), startPoint: .leading, endPoint: .trailing)
                                .frame(width: 30)

                            Rectangle().fill(Color("BatteryBackground"))

                        }
                        .frame(width: size.width + 16)
                        .offset(x:-8)
                        
                    )
                    .overlay(
                        GeometryReader { geo in
                            Color.clear.onAppear() {
                                self.size = geo.size
                                
                            }
                            
                        }
                        
                    )
                    .offset(x:-(size.width))
                    
                }

            }
            
        }
        .padding(.horizontal, 14)
        .frame(height: 86)
        .onHover { hover in
            withAnimation(Animation.easeOut.delay(self.hover ? 1.2 : 0.1)) {
                self.hover = hover
                
            }
            
        }
        .onAppear() {
            self.update = self.updates.available != nil ? true : false
            
        }
        .onChange(of: self.bluetooth.connected, perform: { newValue in
            if newValue.count == 0 && self.manager.menu == .devices {
                withAnimation(Animation.easeOut) {
                    self.manager.menu = .settings

                }
                
            }
           
        })
        .onChange(of: self.updates.available, perform: { newValue in
            withAnimation(Animation.easeOut.delay(0.1)) {
                self.update = newValue != nil ? true : false
                
            }

        })
        
    }
    
}

struct ModalIcon: View {
    @EnvironmentObject var manager:AppManager

    @Namespace private var animation

    var body: some View {
        VStack {
            ZStack {
                if let icon = self.manager.device?.type.icon {
                    Image(systemName: icon).resizable().aspectRatio(contentMode: .fit).matchedGeometryEffect(id: "icon", in: animation)

                }
                else {
                    Image("ChargingIcon").resizable().aspectRatio(contentMode: .fit).matchedGeometryEffect(id: "icon", in: animation)
                        
                }
                
            }
            .frame(width: 28, height: 28)
            .foregroundColor(Color("BatterySubtitle"))
            .offset(y:1)
            
        }
        .frame(width:50, height: 50)
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .background(Color.clear)
        
    }
    
}

struct ModalStatsSubview: View {
    @EnvironmentObject var manager:BatteryManager

    var body: some View {
        HStack {
            
        }
        
    }
    
}



struct ModalIndicator: View {
    @EnvironmentObject var battery:BatteryManager
    @EnvironmentObject var manager:WindowManager
    @EnvironmentObject var stats:StatsManager

    @State private var type:ModalAlertTypes
    @State private var icon:Bool
    @State private var title:String = ""
    @State private var subtitle:String = ""

    init(_ type:ModalAlertTypes) {
        self._type = State(initialValue: type)
        self._icon = State(initialValue: false)

    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                ModalIcon()
//                    .opacity(self.details ? 1.0 : 0.0)
//                    .scaleEffect(self.details ? 1.0 : 0.9)

                VStack(alignment: .leading, spacing: 2) {
                    Text(self.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    ViewMarkdown($subtitle)
                    
                }
                .padding(0)
//                .opacity(self.details ? 1.0 : 0.0)
                
                Spacer()
                
                //RadialProgressContainer()
                
            }
            
        }
        .padding(.vertical, 14)
        .padding(.trailing, 16)
        .padding(.leading, 18)
        //.frame(width: self.manager.state.size.width)
        .onAppear() {
            self.title = self.stats.title
            self.subtitle = self.stats.subtitle

        }
        .onChange(of: self.stats.title) { newValue in
            self.title = newValue

        }
        .onChange(of: self.stats.subtitle) { newValue in
            self.subtitle = newValue

        }
        .onChange(of: self.manager.state) { newValue in
//            if newValue == .reveal {
//                withAnimation(.interactiveSpring(response: 1.0, dampingFraction: 0.8, blendDuration: 0.2)) {
//                    self.icon = true
//                    
//                }
//                
//            }
            
        }
            
    }
    
}

struct ModalMask: View {
    @State private var keyframe = Array<AnimationObject>()

    init() {
//        self._keyframe = State(initialValue: [
//            .init(.init(opacity: 1.0, width: 40, height: 120, blur: 0), duration: 4.3, delay:4.0, easing: .bounce, label: "intro"),
//            .init(.init(opacity: 1.0, width: 420, height: 120, blur: 0), duration: 3.8, delay:6.0, easing: .bounce, label: "next")])

        
//    case .initial : return .init(width: 240, height: 240)
//    case .begin : return .init(width: 40, height: 40)
//    case .pinhole : return .init(width: 120, height: 120)
//    case .reveal : return .init(width: 400, height: 120)
//    case .detailed : return .init(width: 410, height: 210)
//    case .stats : return .init(width: 410, height: 260)
//    case .settings : return .init(width: 410, height: 390)
//    case .dismiss : return .init(width: 120, height: 120)
    }
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius:12, style: .continuous)
                .fill(Color("BatteryBackground"))
                //.timeline($keyframe)
//            RoundedRectangle(cornerRadius: self.window.state.radius, style: .continuous)
//                .frame(width: self.window.state.size.width, height: self.window.state.size.height)
         
            Spacer()
            
        }
        
    }
    
}

struct ModalView: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var window:WindowManager

    @State private var type:ModalAlertTypes
    @State private var final:ModalAnimationTypes
    @State private var scale:CGFloat = 0.0
    @State private var keyframe = Array<AnimationObject>()
    
    @Binding var size:CGSize

    init(_ type:ModalAlertTypes, size:Binding<CGSize>) {
        self._type = State(initialValue: type)
        self._final = State(initialValue: type == .userInitiated ? .detailed : .reveal)
        self._size = size
//        self._keyframe = State(initialValue: [
//            .init(.init(opacity: 0.8, width: 120, height: 120, blur: 0.0), duration: 4),
//            .init(.init(opacity: 1.0, width: 410, height: 120, blur: 0), duration: 0.3)]
//        )
//        
    }
    
    var body: some View {
        VStack() {
            GeometryReader { geometry in
                VStack {
                    ModalIndicator(self.type)
                                        
                    ModalMenuView()
                    
                }
                .clipped()
                .background(GeometryReader { geometry in
                    Color.clear.onAppear() {
                        self.size = geometry.size

                    }
                    
                })

            }

        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Color("BatteryBackground"))
                    //.opacity(self.window.state.opacity)
//                    .onHover(perform: { hover in
//                        self.window.hover = hover ? 1 : 0
//                        
//                    })
                
            }
            .opacity(window.opacity)

        )
        .mask(
            ModalMask()
 
        )
//        .scaleEffect(self.window.state.scale, anchor: .top)
//        .blur(radius: self.window.state.blur)
//        .onAppear() {
//            if self.manager.alert == nil {
//                withAnimation(Animation.easeOut(duration: self.window.state.duration).delay(0.2)) {
//                    self.window.state = .pinhole
//                    self.window.active = 0
//                    
//                }
//                
//            }
//            
//        }
//        .onChange(of: self.window.state) { newValue in
//            if let next = ModalAnimationTypes(rawValue: newValue.rawValue + 1) {
//                if next.automatic(type) == true {
//                    if next.bounce == 0 {
//                        withAnimation(Animation.easeIn(duration: next.duration).delay(self.window.state.duration + 12)) {
//                            self.window.state = next
//                            
//                        }
//                    }
//                    else {
//                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: next.bounce).delay(self.window.state.duration)) {
//                            self.window.state = next
//                            
//                        }
//                        
//                    }
//                    
//                }
//                
//            }
//            
//        }
        
    }
    
}

struct ModalAligment: View {
    @EnvironmentObject var window:WindowManager

    @State var type:ModalAlertTypes
    @State var size:CGSize = .zero

    init(_ type: ModalAlertTypes) {
        self._type = State(initialValue: type)

    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack() {
                Color.clear
                
                ModalView(self.type, size: $size)
                
            }
                        
        }
        .frame(width: 440, height: 410)
        .background(Color.clear)
        
    }
    
}

struct ModalContainer: View {
    @State var type:ModalAlertTypes
    @State var device:BluetoothObject?

    init(_ type: ModalAlertTypes, device:BluetoothObject?) {
        self._type = State(initialValue: type)
        self._device = State(initialValue: device)
        
    }
    
    var body: some View {
        VStack {
            HUDView()
            //ModalAligment(self.type)
          
        }
        .environmentObject(WindowManager.shared)
        .environmentObject(AppManager.shared)
        .environmentObject(BatteryManager.shared)
        .environmentObject(SettingsManager.shared)
        .environmentObject(UpdateManager.shared)
        .environmentObject(StatsManager.shared)
        .environmentObject(BluetoothManager.shared)

    }
    
}

