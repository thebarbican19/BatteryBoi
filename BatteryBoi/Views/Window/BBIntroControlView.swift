//
//  BBIntroControlView.swift
//  BatteryBoi
//
//  Created by Gemini on 12/30/25.
//

import SwiftUI

struct BBIntroControlView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Centered Window")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Closing this window will exit the application.")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: {
                // Terminates the entire app immediately
                NSApplication.shared.terminate(nil)
            }) {
                Text("Close & Exit App")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 400, height: 250)
        // Solid black background set in SwiftUI
        .background(Color.black)
        .onDisappear {
             // Optional: Quits the app if the window is closed by any means
             NSApplication.shared.terminate(nil)
        }
    }
}
