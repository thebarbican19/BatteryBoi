//
//  Extensions.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/6/23.
//

import Foundation
import SwiftUI
import Combine

struct ViewScrollMask: ViewModifier {
    @State var padding:CGFloat
    
    @Binding var scroll:CGPoint

    func body(content: Content) -> some View {
        content.mask(
            GeometryReader { geo in
                HStack(spacing:0) {
                    LinearGradient(gradient: Gradient(colors: [
                        .black.opacity(opacity(for: scroll.x)),
                        .black.opacity(1),
                    ]), startPoint: .leading, endPoint: .trailing).frame(width: padding)
                    
                    Rectangle().fill(.black).frame(width:geo.size.width - padding)
                 
                }
                
            }
            
        )
        
    }
    
    public func opacity(for offset: CGFloat) -> Double {
        let start: CGFloat = 0.0
        let end: CGFloat = -8.0
               
        if offset >= start {
            return 1.0
            
        }
        else if offset <= end {
            return 0.0
            
        }
        else {
            return Double(1.0 + (offset / 8.0))
            
        }
        
    }
    
}

struct ViewMarkdown: View {
    @Binding var text:String
    
    @State private var components = Array<String>()

    init(_ content:Binding<String>) {
        self._text = content
        
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<components.count, id: \.self) { number in
                if number.isMultiple(of: 2) {
                    Text(components[number])
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("BatterySubtitle"))
                } 
                else {
                    Text(components[number])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("BatteryTitle").opacity(0.9))
                }
                
            }
            
        }
        .lineLimit(1)
        .onChange(of: self.text) { newValue in
            self.components = newValue.components(separatedBy: "**")

        }
        
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
    
    public func localise(_ params: [CVarArg]? = nil, comment:String? = nil) -> String {
        var key = self
        var output = NSLocalizedString(self, tableName: "LocalizableMain", comment: comment ?? "")

        if let number = params?.first(where: { $0 is Int}) as? Int {
            switch number {
                case 1 : key = "\(key)_Single"
                default : key = "\(key)_Plural"

            }
            
        }
        
        if output == self {
            output = NSLocalizedString(key, tableName: "LocalizableMain", comment: comment ?? "")

        }
        
        if let params = params {
            return String(format: output, arguments: params)

        }
        
        return output

    }
}

extension Date {
    public func string(_ format:String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale.current
        
        return formatter.string(from: self)
        
    }
    
    public var formatted:String {
        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: self, to: Date())
        if let days = components.day, days > 1 {
            return "TimestampMinuteDaysLabel".localise([days])

        }
        
        if let hours = components.hour, hours > 1 {
            return "TimestampHourFullLabel".localise([hours])
            
        }
        
        return "TimestampNowLabel".localise()
            
    }
    
    public var now:Bool {
        if let seconds = Calendar.current.dateComponents([.second], from: self, to: Date()).second {
            if seconds < 60 {
                return true
                
            }
            
        }

        return false
        
    }
    
    public var time:String {
        let locale = NSLocale.current
        let formatter = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale)
        
        if let formatter = formatter {
            if formatter.contains("a") == true {
                return self.string("hh:mm a")
                
            }
            else {
                return self.string("HH:mm")

            }
            
        }
        
        return "AlertDeviceUnknownTitle".localise()

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
    
    func mask(_ padding:CGFloat = 10, scroll:Binding<CGPoint>) -> some View {
        self.modifier(ViewScrollMask(padding: padding, scroll: scroll))

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
        self.save(string: key.rawValue, value: value)
        
    }
    
    static func save(string key:String, value:Any?) {
        if let value = value {
            main.set(Date(), forKey: "\(key)_timestamp")
            main.set(value, forKey: key)
            main.synchronize()
            
            if let system = SystemDefaultsKeys(rawValue: key) {
                changed.send(system)

            }

            print("\n\n💾 Saved \(value) to '\(key)'\n\n")
            
        }
        else {
            main.removeObject(forKey: key)
            main.synchronize()

            if let system = SystemDefaultsKeys(rawValue: key) {
                changed.send(system)

            }

        }
        
    }
}

extension CodingUserInfoKey {
    static let device = CodingUserInfoKey(rawValue: "device")!
    static let connected = CodingUserInfoKey(rawValue: "connected")!

}

extension NSWindow: SystemMainWindow {
    var canBecomeKeyWindow: Bool {
        return true
        
    }
    
}

protocol SystemMainWindow {
    var canBecomeKeyWindow: Bool { get }
    
}
