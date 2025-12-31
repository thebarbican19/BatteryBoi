//
//  BBMenubarConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 12/29/25.
//

import Foundation
import SwiftUI
import DynamicColor

enum MenubarScheme: String, CaseIterable {
    case monochrome
    case polychrome

    var warning: Color {
        switch self {
            case .monochrome: return Color("BatteryDefault").opacity(0.7)
            case .polychrome: return Color(hexString: "#ed7671")
        }
    }

    var efficient: Color {
        switch self {
            case .monochrome: return Color("BatteryDefault")
            case .polychrome: return Color("BatteryEfficient")
        }
    }
}

enum MenubarStyle: String, CaseIterable {
    case original
    case transparent
    case text

    var size: CGSize {
        return .init(width: 32, height: 15)
		
    }

    var font: CGFloat {
        switch self {
            case .original: return 11
            case .transparent: return 11
            case .text: return 14
			
        }
		
    }

    var kerning: CGFloat {
        switch self {
            case .original: return -0.4
            case .transparent: return -0.4
            case .text: return 1.0
			
        }
		
    }

    var spacing: CGFloat {
        switch self {
            case .original: return 0.5
            case .transparent: return 0.5
            case .text: return 1.0
			
        }
		
    }

    var icon: CGSize {
        switch self {
            case .original: return .init(width: 5, height: 8)
            case .transparent: return .init(width: 5, height: 8)
            case .text: return .init(width: 7, height: 10)
			
        }
		
    }

    var padding: CGFloat {
        switch self {
            case .original: return 1.6
            case .transparent: return 1.6
            case .text: return 0.0
			
        }
		
    }

    var stub: CGFloat {
        switch self {
            case .original: return 0.6
            case .transparent: return 0.6
            case .text: return 0.0
			
        }
		
    }
	
}
