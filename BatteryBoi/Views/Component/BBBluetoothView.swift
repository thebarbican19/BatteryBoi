//
//  BBBluetoothView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/6/23.
//

import SwiftUI

/*
struct BluetoothIcon: View {
    @State private var item:BluetoothObject?
    @State private var icon:String
    @State private var animation:Namespace.ID
    
    @Binding private var style:RadialStyle

    init(_ item:BluetoothObject?, style:Binding<RadialStyle>, animation:Namespace.ID) {
        self._item = State(initialValue: item)
        self._icon = State(initialValue: item?.type.icon ?? AppManager.shared.appDeviceType.icon)
        self._animation = State(initialValue: animation)
        
        self._style = style

    }
    
    var body: some View {
        HStack {
            ZStack {
                if self.item == nil || self.item?.battery.percent != nil {
                    RadialProgressMiniContainer(self.item, style: $style)
                    
                    Image(systemName: self.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatterySubtitle"))
                        .padding(2)
                        .background(
                            Circle()
                                .fill(self.style == .light ? Color("BatteryTitle") : Color("BatteryButton"))
                                .blur(radius: 2)
                            
                        )
                        .matchedGeometryEffect(id: self.icon, in: animation)
                        .offset(x:12, y:12)
                    
                }
                else {
                    Image(systemName: self.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatterySubtitle"))
                        .padding(2)
                        .matchedGeometryEffect(id: item?.type.icon ?? "laptopcomputer", in: animation)
                    
                }

            }
            
            Spacer().frame(width:18)
            
        }
        
    }
    
}
*/

struct BluetoothItem: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var battery:BatteryManager

    @Binding var hover:Bool

    @State var item:SystemDeviceObject?
    @State var style:RadialStyle = .light

    @Namespace private var animation
    
    init(_ item:SystemDeviceObject?, hover:Binding<Bool>) {
        self._item = State(initialValue: item)
        self._hover = hover
        
    }

    var body: some View {
        HStack(alignment: .center) {
            //BluetoothIcon(item, style: $style, animation: animation)

            VStack(alignment: .leading) {
                if let item = self.item {
                    Text(item.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatteryTitle"))
                        .padding(0)
                    
                    HStack {
                        if self.hover == true {
//                            if item.connected == .disconnected {
//                                Text("BluetoothDisconnectedLabel".localise())
//                        
//                            }
//                            else {
//                                if let percent = item.battery.percent {
//                                    Text("AlertSomePercentTitle".localise([Int(percent)]))
//                                    
//                                }
//                                else {
//                                    Text("BluetoothInvalidLabel".localise())
//                                        
//                                }
//                                
//                            }
                            
                        }
                        
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color("BatterySubtitle"))
                    
                }
                else {
                    if let type = AppManager.shared.appDeviceType.name(true) {
                        Text(type)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatteryTitle"))
                            .padding(0)
                        
                        if self.hover == true {
                            Text("AlertSomePercentTitle".localise([Int(battery.percentage)]))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color("BatterySubtitle"))
                            
                        }
                        
                    }
                    
                }
                
            }
                                    
        }
        .frame(height: 60)
        .padding(.leading, 16)
        .padding(.trailing, 26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(self.style == .light ? Color("BatteryTitle") : Color("BatteryButton"))
            
        )
        .onTapGesture {
            withAnimation(Animation.easeOut) {
                //self.manager.device = item
                
            }
            
        }
        .onHover { hover in
            switch hover {
                case true : NSCursor.pointingHand.push()
                default : NSCursor.pop()
                
            }
            
        }
//        .onChange(of: manager.device) { newValue in
//            withAnimation(Animation.easeOut) {
//                if newValue == item {
//                    self.style = .light
//                    
//                }
//                else {
//                    self.style = .dark
//                    
//                }
//                
//            }
//            
//        }
        .onAppear() {
//            if AppManager.shared.device == item {
//                self.style = .light
//                
//            }
//            else {
//                self.style = .dark
//
//            }
            
        }
        
    }
    
}
