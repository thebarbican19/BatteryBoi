//
//  BBStandardWidget.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 11/30/23.
//

import Foundation
import SwiftUI
import WidgetKit
import Intents

struct WidgetStandard: Widget {
    @Environment(\.widgetFamily) var family
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.batteryboi.widget.standard", provider: WidgetProvider()) { entry in
            if family == .systemSmall {
                if #available(iOS 17.0, *) {
                    DeleteMeEntryView(entry: entry)
                        .containerBackground(.fill.tertiary, for: .widget)
                        .background(.green)
                    
                }
                else {
                    DeleteMeEntryView(entry: entry)
                        .padding()
                        .background(.gray)
                    
                }
                
            }
            else {
                Rectangle().background(.red)
                
            }
            
        }
        .configurationDisplayName("BatteryBoi")
        .description("View the Status of your Devices, even your Mac!")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
        
    }
    
}

struct DeleteMeEntryView : View {
    var entry: WidgetProvider.Entry

    var body: some View {
        VStack {
            if let device = entry.device {
                Text("Time:")
                Text(entry.date, style: .time)
                
                Text(device.name)
                
            }
            else {
                Text("No Device Set")
                
            }
            
        }
        
    }
    
}
