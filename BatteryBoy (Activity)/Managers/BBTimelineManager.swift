//
//  BBTimelineManager.swift
//  BatteryBoi (iOS)
//
//  Created by Joe Barbour on 11/30/23.
//

import Foundation
import WidgetKit
import Intents
import Combine

struct WidgetDeviceObject:TimelineEntry {
    var date: Date
//    var device:SystemDeviceObject?
//    
//    init(_ device: SystemDeviceObject? = nil) {
//        self.date = Date()
//        self.device = device
//        
//    }
	
	init() {
		self.date = Date.now
	}
    
}

struct WidgetProvider: TimelineProvider {
    public var cancellable = Set<AnyCancellable>()

    func placeholder(in context: Context) -> WidgetDeviceObject {
        WidgetDeviceObject()
        
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetDeviceObject) -> ()) {
        self.widgetCreateEntry(context, completion: completion)
        
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetDeviceObject>) -> ()) {
        var entries: [WidgetDeviceObject] = []
        
        self.widgetCreateEntry(context) { device in
            entries.append(device)
            completion(Timeline(entries: entries, policy: .atEnd))

        }
        
    }
    
    func widgetCreateEntry(_ context:Context, completion: @escaping (WidgetDeviceObject) -> ()) {
//        if let device = AppManager.shared.devices.sorted(by: { $0.polled ?? Date.distantPast > $1.polled ?? Date.distantPast }).first {
//            completion(.init(device))
//
//        }
//        else {
//            completion(.init(nil))
//
//        }
//    
        //.store(in: cancellable)

    }
    
    
}
