//
//  Extensions.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/6/23.
//

import Foundation
import SwiftUI
import Combine

enum ViewScrollMaskPosition {
    case top
    case bottom
    case left
    case right
    
}

struct ViewScrollMask: ViewModifier {
    @State var positions:Array<ViewScrollMaskPosition>
    @State var padding:CGFloat

    func body(content: Content) -> some View {
        content.mask(
            GeometryReader { geo in
                VStack(spacing:0) {
                    LinearGradient(gradient: Gradient(colors: [
                        .black.opacity(self.positions.contains(.top) ? 0 : 1),
                        .black.opacity(1),
                    ]), startPoint: .top, endPoint: .bottom).frame(height: padding)
                    
                    Rectangle().fill(.black).frame(height:geo.size.height - (padding * 2))
                    
                    LinearGradient(gradient: Gradient(colors: [
                        .black.opacity(1),
                        .black.opacity(self.positions.contains(.bottom) ? 0 : 1),
                    ]), startPoint: .top, endPoint: .bottom).frame(height: padding)
                    
                }
                
            }
            
        )
        
    }
    
}

struct ViewTextStyle: ViewModifier {
    @State var size:CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 14.0, macOS 13.0, watchOS 7.0, tvOS 14.0, *) {
            content.font(.system(size: self.size, weight: .bold)).lineLimit(1).tracking(-0.4)
            
        }
        else {
            content.font(.system(size: self.size, weight: .bold)).lineLimit(1)

        }
        
    }
    
}

extension String {
    public func append(_ string:String, seporator:String) -> String {
        return "\(self)\(seporator)\(string)"
        
    }
    
    public func width(_ font: NSFont) -> CGFloat {
        let attribute = NSAttributedString(string: self, attributes: [NSAttributedString.Key.font: font])
        
        return attribute.size().width
        
    }

}

extension View {
    func inverse<M: View>(_ mask: M) -> some View {
        let inversed = mask
            .foregroundColor(.black)
            .background(Color.white)
            .compositingGroup()
            .luminanceToAlpha()
        
        return self.mask(inversed)
        
    }
    
    func mask(_ position:Array<ViewScrollMaskPosition> = [.top, .bottom], padding:CGFloat = 10) -> some View {
        self.modifier(ViewScrollMask(positions: position, padding: padding))

    }
    
    func style(_ font:CGFloat) -> some View {
        self.modifier(ViewTextStyle(size: font))

    }

}

extension UserDefaults {
    static let changed = PassthroughSubject<SystemDefaultsKeys, Never>()

    static var main:UserDefaults {
        return UserDefaults()
        
    }
    
    static var list:Array<SystemDefaultsKeys> {
        return UserDefaults.main.dictionaryRepresentation().keys.compactMap({ SystemDefaultsKeys(rawValue:$0) })
        
    }

    static func save(_ key:SystemDefaultsKeys, value:Any?) {
        if let value = value {
            main.set(Date(), forKey: "\(key.rawValue)_timestamp")
            main.set(value, forKey: key.rawValue)
            main.synchronize()
            
            changed.send(key)

            print("\n\n💾 Saved \(value) to '\(key.rawValue)'\n\n")
            
        }
        else {
            main.removeObject(forKey: key.rawValue)
            main.synchronize()

            changed.send(key)

        }
        
    }
    
}
