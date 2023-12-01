//
//  BBTimelineManager.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 11/30/23.
//

import Foundation
import WidgetKit
import Intents

struct WidgetDeviceObject:TimelineEntry {
    var date: Date
    var device:String
    
}

struct WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetDeviceObject {
        WidgetDeviceObject(date: Date(), device: "😀")
        
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetDeviceObject) -> ()) {
        let entry = WidgetDeviceObject(date: Date(), device: "😀")
        completion(entry)
        
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetDeviceObject>) -> ()) {
        var entries: [WidgetDeviceObject] = []

        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = WidgetDeviceObject(date: entryDate, device: "😀")
            entries.append(entry)
            
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        
        completion(timeline)
        
    }
    
}
