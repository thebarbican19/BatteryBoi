//
//  BBIntroView.swift
//  BatteryBoi
//
//  Created by Gemini on 12/30/25.
//

import SwiftUI

struct BBIntroView: View {
    var body: some View {
        ZStack {
            // The semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // The centered text
            Text("AwesomeApp")
                .font(.system(size: 100, weight: .black, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
