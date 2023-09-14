//
//  BBUpdateView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/12/23.
//

import SwiftUI

struct UpdatePromptView: View {
    @EnvironmentObject var update:UpdateManager

    var body: some View {
        if self.update.available != nil {
            HStack(alignment: .top, spacing: 3) {
                Circle()
                    .fill(Color("BatteryEfficient"))
                    .frame(width: 5, height: 5)
                    .offset(y:5)
                
                Text("UpdateStatusNewLabel".localise())

            }
            .padding(0)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color("BatteryEfficient"))
            .lineLimit(2)
            .padding(.top, 10)
            .onHover { hover in
                switch hover {
                    case true : NSCursor.pointingHand.push()
                    default : NSCursor.pop()
                    
                }
                
            }
            .onTapGesture {
                SettingsManager.shared.settingsAction(.init(.appInstallUpdate))

            }
            
        }
        else {
            EmptyView()
            
        }
        
    }
    
}
