//
//  BBNavigationView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/19/23.
//

import SwiftUI

struct NavigationContainer: View {
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
                            
                            if self.manager.menu == .devices {
                                if self.manager.device != nil {
                                    BluetoothItem(nil, hover:$hover)
                                    
                                }
                                
                            }
                            
                            ForEach(bluetooth.list, id: \.address) { item in
                                if self.manager.menu == .devices {
                                    BluetoothItem(item, hover:$hover)
                                    
                                }
                                
                            }
                            
                            if self.bluetooth.connected.count > 0 {
                                Spacer().frame(width: size.width)

                            }
                            else {
                                Spacer().frame(width: (size.width / 2))

                            }
                            
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
                        .offset(x:self.bluetooth.connected.count > 0 ? -8.0 : 48.0)
                        
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
