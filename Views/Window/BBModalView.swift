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
    case expand
    case dismiss
    
    var blur:CGFloat {
        switch self {
            case .initial : return 12
            case .begin : return 12.0
            case .pinhole : return 2.0
            case .reveal : return 0.0
            case .expand : return 0.0
            case .dismiss : return 4.0

        }
        
    }
    
    var opacity:Double {
        switch self {
            case .initial : return 0.05
            case .begin : return 0.05
            case .pinhole : return 1.0
            case .reveal : return 1.0
            case .expand : return 1.0
            case .dismiss : return 0.0

        }
        
    }
    
    var size:CGSize {
        switch self {
            case .initial : return .init(width: 240, height: 240)
            case .begin : return .init(width: 40, height: 40)
            case .pinhole : return .init(width: 120, height: 120)
            case .reveal : return .init(width: 400, height: 120)
            case .expand : return .init(width: 410, height: 210)
            case .dismiss : return .init(width: 120, height: 120)
    
        }
        
    }
    
    var duration:CGFloat {
        switch self {
            case .initial : return 0.01
            case .begin : return 1.4
            case .pinhole : return 0.5
            case .reveal : return 0.5
            case .expand : return 3.0
            case .dismiss : return 0.18

        }
    }
    
    func automatic(_ modal:ModalAlertTypes) -> Bool {
        switch self {
            case .initial : return false
            case .begin : return true
            case .pinhole : return true
            case .reveal : return true
            case .expand : return modal == .userInitiated ? true : false
            case .dismiss : return false

        }
        
    }
    
    var radius:CGFloat {
        switch self {
            case .initial : return 66
            case .begin : return 66
            case .pinhole : return 66
            case .reveal : return 66
            case .expand : return 46
            case .dismiss : return 66

        }
        
    }
    
    var bounce:CGFloat {
        switch self {
            case .initial : return 0.0
            case .begin : return 0.0
            case .pinhole : return 0.0
            case .reveal : return 8.0
            case .expand : return 2.0
            case .dismiss : return 3.0

        }
        
    }
    
    var content:Bool {
        switch self {
            case .initial : return false
            case .begin : return false
            case .pinhole : return false
            case .reveal : return true
            case .expand : return true
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

}

struct ModalIcon: View {
    var body: some View {
        VStack {
            Image("ChargingIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .foregroundColor(Color.white)
                .offset(y:1)
            
        }
        .padding(.leading, 6)
        .frame(width:50, height: 50)
        .background(Color.clear)
        
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
        HStack(alignment: .center) {
            ModalIcon().opacity(self.manager.state.content ? 1.0 : 0.0)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                ViewMarkdown($subtitle)
               
            }
            .padding(0)
            .opacity(self.manager.state.content ? 1.0 : 0.0)
            
            Spacer()
            
            RadialProgressContainer()

        }
//        .overlay(
//            ZStack(alignment: .center) {
//                BatteryContainer(.init(width: 32, height: 15), radius: 5, font: 11)
//
//            }
//            .background(Color.green)
//            .scaleEffect(4.0)
//
//        )
        .padding(.vertical, 14)
        .padding(.trailing, 16)
        .padding(.leading, 18)
        .frame(width: self.manager.state.size.width)
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
            if newValue == .reveal {
                withAnimation(.interactiveSpring(response: 1.0, dampingFraction: 0.8, blendDuration: 0.2)) {
                    self.icon = true
                    
                }
                
            }
            
        }
            
    }
    
}

struct ModalView: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var window:WindowManager

    @State private var type:ModalAlertTypes
    @State private var final:ModalAnimationTypes
    @State private var scale:CGFloat = 0.0

    init(_ type:ModalAlertTypes) {
        self._type = State(initialValue: type)
        self._final = State(initialValue: type == .userInitiated ? .expand : .reveal)
        
    }
    
    var body: some View {
        VStack() {
            ModalIndicator(self.type)

            Spacer()

            SettingsContainer()

        }
        .frame(width: 430, height: 210)
        .background(
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(Color("BatteryBackground"))
                .opacity(self.window.state.opacity)
                .offset(y:self.window.state == .expand ? -4.0 : 0)
                .onHover(perform: { hover in
                    self.window.hover = hover ? 1 : 0
                    
                })
            
        )
        .mask(
            VStack {
                RoundedRectangle(cornerRadius: self.window.state.radius, style: .continuous).fill(Color("BatteryBackground"))
                    .frame(width: self.window.state.size.width, height: self.window.state.size.height)
             
                Spacer()
                
            }
 
        )
        .blur(radius: self.window.state.blur)
        .scaleEffect(0.96 + self.scale)
        .onAppear() {
            if self.manager.alert == nil {
                withAnimation(Animation.easeOut(duration: self.window.state.duration).delay(0.2)) {
                    self.window.state = .pinhole
                    self.window.active = 0
                    
                }
                
            }
            
        }
        .onChange(of: self.window.hover) { newValue in
            if self.window.state == .reveal {
                withAnimation(Animation.easeOut(duration: CGFloat(newValue) > self.scale ? 3.0 : 0.3)) {
                    switch newValue {
                        case 0 : self.scale = 0.0
                        default : self.scale = 0.04
                        
                    }
                                        
                }
                
            }
                                            
        }
        .onChange(of: self.window.state) { newValue in
            if let next = ModalAnimationTypes(rawValue: newValue.rawValue + 1) {
                if next.automatic(type) == true {
                    if next.bounce == 0 {
                        withAnimation(Animation.easeIn(duration: next.duration).delay(self.window.state.duration + 12)) {
                            self.window.state = next
                            
                        }
                    }
                    else {
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: next.bounce).delay(self.window.state.duration)) {
                            self.window.state = next
                            
                        }
                        
                    }
                    
                }
                
            }
            
            if newValue == .expand {
                withAnimation(Animation.easeOut(duration: 0.1)) {
                    self.scale = 0.04
                    
                }
                
            }
            
        }
        
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
            ModalView(type)
            
        }
        .frame(width: 440, height: 260)
        .environmentObject(WindowManager.shared)
        .environmentObject(AppManager.shared)
        .environmentObject(BatteryManager.shared)
        .environmentObject(SettingsManager.shared)
        .environmentObject(UpdateManager.shared)
        .environmentObject(StatsManager.shared)

    }
    
}

struct JModalView_Previews: PreviewProvider {
    static var previews: some View {
        ModalContainer(.userInitiated, device: nil)
        
    }
    
}
