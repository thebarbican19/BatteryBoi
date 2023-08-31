//
//  BBActionView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/15/23.
//

import SwiftUI

struct SettingsScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        
    }
    
}

struct SettingsButton: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var settings:SettingsManager
    @EnvironmentObject var battery:BatteryManager

    @State var item:SettingsActionObject
    @State var hover:Bool = false
    @State var subtitle:String? = nil
    @State var color:String? = nil
    @State var icon:String? = nil

    var body: some View {
        HStack(alignment: .center) {
            Image(icon ?? item.type.icon)
                .font(.system(size: 23, weight: .medium))
                .foregroundColor(self.color == nil ? Color("BatterySubtitle") : Color("BatteryEfficient"))
                .padding(.trailing, 6)
                .padding(.vertical, 8)

            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("BatteryTitle"))
                    .padding(0)
                
                if self.hover == true && self.subtitle != nil {
                    Text(self.subtitle ?? "")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color("BatterySubtitle"))
                    
                }
                
            }
            
        }
        .padding(.vertical, 12)
        .padding(.leading, 18)
        .padding(.trailing, 26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color("BatteryButton"))
            
        )
        .onAppear() {
            if item.type == .appEfficencyMode {
                self.color = self.battery.saver == .efficient ? "BatteryEfficient" : nil
                self.subtitle = self.battery.saver == .efficient ? "SettingsEnabledLabel".localise() : "SettingsDisabledLabel".localise()

            }
            else if item.type == .appUpdateCheck {
                self.subtitle = self.updates.state.subtitle(updates.checked)
                
            }
            else if item.type == .customiseDisplay {
                self.subtitle = self.settings.enabledDisplay(false).type
                self.icon = self.settings.enabledDisplay(false).icon

            }
            
        }
        .onChange(of: self.battery.saver, perform: { newValue in
            withAnimation(Animation.easeOut.delay(0.1)) {
                if item.type == .appEfficencyMode {
                    self.color = self.battery.saver == .efficient ? "BatteryEfficient" : nil
                    self.subtitle = self.battery.saver == .efficient ? "SettingsEnabledLabel".localise() : "SettingsDisabledLabel".localise()

                }
                
            }
            
        })
        .onChange(of: self.updates.state, perform: { newValue in
            withAnimation(Animation.easeOut.delay(0.1)) {
                if item.type == .appUpdateCheck {
                    self.subtitle = self.updates.state.subtitle(updates.checked)
                    
                }
                
            }
            
        })
        .onChange(of: self.settings.display, perform: { newValue in
            withAnimation(Animation.easeOut.delay(0.1)) {
                if item.type == .customiseDisplay {
                    self.subtitle = newValue.type
                    self.icon = newValue.icon
                    
                }

            }
            
        })
        .onTapGesture {
            SettingsManager.shared.settingsAction(item)
            
        }
        .onHover { hover in
            withAnimation(Animation.easeOut.delay(self.hover ? 1.2 : 0.1)) {
                self.hover = hover
                
            }
            
            switch hover {
                case true : NSCursor.pointingHand.push()
                default : NSCursor.pop()
                
            }
            
        }
        
    }
    
}

struct SettingsButtonQuit: View {
    @State var proxy:GeometryProxy
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color("BatteryBackground").opacity(0.0), Color("BatteryBackground")]), startPoint: .leading, endPoint: .trailing)
                .offset(x:-23)
            
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color("BatteryButton"))
                .overlay(
                    Image(systemName: "power")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("BatterySubtitle"))
                
                )
                .onHover { hover in
                    switch hover {
                        case true : NSCursor.pointingHand.push()
                        default : NSCursor.pop()
                        
                    }
                    
                }
                .onTapGesture {
                    SettingsManager.shared.settingsAction(.init(.appQuit))
                    
                }
            
        }
        .position(x:proxy.size.width - 48, y:29)
        .frame(width:58, height: 58)
        
    }
    
}

struct SettingsContainer: View {
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var settings:SettingsManager
    
    @State var update:Bool = false
    @State var scroll:CGPoint = .zero

    var body: some View {
        ZStack {
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(settings.menu, id: \.self) { item in
                            SettingsButton(item: item)
                            
                        }
                        
                        Spacer().frame(width: 32)
                        
                    }
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: SettingsScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).origin)
                        
                    })
                    .onPreferenceChange(SettingsScrollOffsetKey.self) { value in
                        if WindowManager.shared.state == .expand {
                            self.scroll = value

                        }
                        
                    }
                    
                }
                .coordinateSpace(name: "scroll")
                .mask(30, scroll: $scroll)
                .padding(.leading, 20)
                .padding(.trailing, 46)
                

                SettingsButtonQuit(proxy: geo)

            }

        }
        .padding(.horizontal, 6)
        .frame(height: 76)
        .onAppear() {
            self.update = updates.available != nil ? true : false
            
        }
        .onChange(of: self.updates.available, perform: { newValue in
            withAnimation(Animation.easeOut.delay(0.1)) {
                self.update = newValue != nil ? true : false
                
            }

        })
        
    }
    
}


