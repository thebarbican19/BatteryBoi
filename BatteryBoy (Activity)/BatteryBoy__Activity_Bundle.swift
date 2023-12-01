//
//  BatteryBoy_Activit.swift
//  BatteryBoy (Activity)
//
//  Created by Joe Barbour on 11/20/23.
//

import WidgetKit
import SwiftUI
import CloudKit

@main
struct BatteryBoy__Activity_Bundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        WidgetStandard()

        WidgetDynamicIsland()
        
    }
    
}
