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
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.batteryboi.widget.standard", provider: WidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                DeleteMeEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
                
            } 
            else {
                DeleteMeEntryView(entry: entry)
                    .padding()
                    .background()
                
            }
            
        }
        .configurationDisplayName("BatteryBoi")
        .description("View the Status of your Devices, even your Mac!")
        .supportedFamilies([.systemSmall])
        
    }
    
}


struct DeleteMeEntryView : View {
    var entry: WidgetProvider.Entry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)

            Text("Emoji:")
            Text(entry.device)
            
        }
        
    }
    
}
