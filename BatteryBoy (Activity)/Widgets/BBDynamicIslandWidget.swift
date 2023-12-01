//
//  BatteryBoy__Activity_.swift
//  BatteryBoy (Activity)
//
//  Created by Joe Barbour on 11/20/23.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetDynamicIsland:Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CloudNotifyAttributes.self) { context in
            BatteryLiveActivity(context: context)

        }
        dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Text("Device: \(context.attributes.device)")
                        
                    }
                    .font(.system(size: 11, weight: .medium))


                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack {
                        Text("Timstamp: \(context.state.timestamp.formatted())")
                        
                    }
                    .font(.system(size: 11, weight: .bold))


                }
                
            } compactLeading: {
                Text("CL")
      
            } compactTrailing: {
                HStack(spacing: 0) {
                    Text("\(context.state.battery)").foregroundColor(Color("BatteryTitle"))
                    
                    Text("%").foregroundColor(Color("BatterySubtitle"))

                }
                .font(.system(size: 11, weight: .medium))

            } minimal: {
                Text("\(context.state.battery)%")

            }

        }

    }
    
}

struct BatteryLiveActivity:View {
    var context:ActivityViewContext<CloudNotifyAttributes>
    
    var body: some View {
        Text("Charging: \(context.state.battery)")
        Text("Device: \(context.attributes.device)")

    }
    
}

