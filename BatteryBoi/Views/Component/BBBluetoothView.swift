//
//  BBBluetoothView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/6/23.
//

import SwiftUI

struct BluetoothItem: View {
    @Binding var hover:Bool

    @State var item:BluetoothObject?
    
    @Namespace private var animation

    var body: some View {
        HStack(alignment: .center) {
            if item?.battery.percent != nil {
                ZStack {
                    RadialProgressMiniContainer(self.item)
                    
                    Image(systemName: item?.type.icon ?? "laptopcomputer")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("BatterySubtitle"))
                        .padding(2)
                        .background(
                            Circle()
                                .fill(Color("BatteryButton"))
                                .blur(radius: 2)
                            
                        )
                        .matchedGeometryEffect(id: item?.type.icon ?? "laptopcomputer", in: animation)
                        .offset(x:12, y:12)
                    
                }
                
                Spacer().frame(width:18)
                
            }
            else {
                Image(systemName: item?.type.icon ?? "laptopcomputer")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("BatterySubtitle"))
                    .padding(2)
                    .matchedGeometryEffect(id: item?.type.icon ?? "laptopcomputer", in: animation)
                
                Spacer().frame(width:8)

            }

            VStack(alignment: .leading) {
                if let item = self.item {
                    Text(item.device ?? item.type.type.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("BatteryTitle"))
                        .padding(0)
                    
                    if self.hover == true {
                        if item.connected == .disconnected {
                            Text("BluetoothDisconnectedLabel".localise())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color("BatterySubtitle"))
                            
                        }
                        else {
                            if let percent = item.battery.percent {
                                Text("AlertSomePercentTitle".localise([Int(percent)]))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color("BatterySubtitle"))
                                
                            }
                            else {
                                Text("BluetoothInvalidLabel".localise())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color("BatterySubtitle"))
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
                                    
        }
        .frame(height: 60)
        .padding(.leading, 16)
        .padding(.trailing, 26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color("BatteryButton"))
            
        )
        .onTapGesture {
            //AppManager.shared.device = item
            
        }
        .onHover { hover in
            switch hover {
                case true : NSCursor.pointingHand.push()
                default : NSCursor.pop()
                
            }
            
        }
        
    }
    
}
