//
//  BatteryBoy__Activity_.swift
//  BatteryBoy (Activity)
//
//  Created by Joe Barbour on 11/20/23.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BatteryBoy__Activity_:Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CloudNotifyAttributes.self) { context in
            BatteryLiveActivity(context: context)

        }
        dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Main")
                    
                }
                
            } compactLeading: {
                Text("CL")
      
            } compactTrailing: {
                Text("CT")
                
            } minimal: {
                Text("-")
                    
            }

        }

    }
    
}

struct BatteryLiveActivity:View {
    var context:ActivityViewContext<CloudNotifyAttributes>
    
    var body: some View {
        Text("Charging: \(context.state.battery)")
        
    }
}

