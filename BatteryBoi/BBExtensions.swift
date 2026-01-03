//
//  Extensions.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/6/23.
//

import Foundation
import SwiftUI
import Combine
import StringMetric

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
            if components.count == 1 {
                Text(components[0])
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("BatterySubtitle"))
                    .lineLimit(3)

            }
            else {
                ForEach(0..<components.count, id: \.self) { number in
                    if number.isMultiple(of: 2) {
                        Text(components[number])
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("BatterySubtitle"))
                            .lineLimit(1)

                    }
                    else {
                        Text(components[number])
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color("BatteryTitle").opacity(0.9))
                            .lineLimit(1)

                    }
                    
                }
                
            }
            
        }
        .onChange(of: self.text) { newValue in
            self.components = newValue.components(separatedBy: "**")

        }
        
    }
    
}

struct ViewTextStyle: ViewModifier {
    @State var size:CGFloat
    @State var kerning:CGFloat
    
    func body(content: Content) -> some View {
        content.font(.system(size: self.size, weight: .bold)).lineLimit(1).tracking(-0.4)

    }

}

extension TimeInterval {
    var boottime:Date {
        let currentTime = Date()
        var bootTime = currentTime
        
        var currentTimeSpec = timespec()
        if clock_gettime(CLOCK_MONOTONIC_RAW, &currentTimeSpec) == 0 {
            let uptimeSinceBoot = Double(currentTimeSpec.tv_sec) + Double(currentTimeSpec.tv_nsec) / 1_000_000_000.0
            bootTime = currentTime.addingTimeInterval(-uptimeSinceBoot)
            
        }

        let advertisementDate = bootTime.addingTimeInterval(self)
        
        return advertisementDate
        
    }
    
}

extension Bool {
    public enum StringFormat {
        case enabled
        case yes
        
    }
    
    public func string(_ type:StringFormat) -> String {
        if type == .enabled {
            switch self {
                case true : return "PermissionsEnabledLabel".localise()
                case false : return "PermissionsDisabledLabel".localise()
                
            }
            
        }
        else {
            switch self {
                case true : return "PermissionsYesLabel".localise()
                case false : return "PermissionsNoLabel".localise()
                
            }
            
        }
        
    }
    
}

extension String? {
    public var empty:Bool {
        if let valid = self {
            return valid.isEmpty ? true : false
            
        }
        
        return true
        
    }
    
}

extension String {
    public func append(_ string:String, seporator:String) -> String {
        return "\(self)\(seporator)\(string)"
        
    }
    
    #if os(macOS)
        public func width(_ font: NSFont) -> CGFloat {
            let attribute = NSAttributedString(string: self, attributes: [NSAttributedString.Key.font: font])
            
            return attribute.size().width
            
        }
        
    #endif
    
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

    public var boolean:Bool {
        switch self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "y" : return true
            case "on" : return true
            case "yes" : return true
            case "1" : return true
            case "true" : return true
            case "yass" : return true //🤩
            case "sure" : return true
            case "yeanah" : return true // 🦘
            case "doit" : return true
            case "haan" : return true
            case "aye" : return true // 🏴󠁧󠁢󠁳󠁣󠁴󠁿
            case "whynot" : return true // 🤷‍♂️
            case "fuckit" : return true
            case "si" : return true // 🇪🇨
            case "yarr" : return true // 🏴‍☠️
            default : return false

        }

    }

    public func jaroWinklerSimilarity(with other: String) -> Double {
        return self.distanceJaroWinkler(between: other)
    }

    public var normalizedDeviceName: String {
        let withoutEmojis = self.unicodeScalars.filter { scalar in
            return scalar.properties.isEmoji == false && scalar.properties.isEmojiPresentation == false
        }.map { String($0) }.joined()

        return withoutEmojis.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "  ", with: " ").lowercased()
    }

}

extension Array<String> {
    public func index(_ index:Int, fallback:String? = nil) -> String? {
        if self.indices.contains(index) {
            return self[index]
            
        }
       
        return fallback

    }
    
}

extension UUID {
    static func device() -> UUID? {
        #if os(macOS)
            let expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
            
            if expert != 0 {
                let serial = IORegistryEntryCreateCFProperty(expert, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String
                IOObjectRelease(expert)
                
                if let uuid = serial {
                    return UUID(uuidString: uuid)
                    
                }
                
            }
        
            return nil
        
        #elseif os(iOS)
            return UIDevice.current.identifierForVendor

        #endif
        
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
        
        if let minutes = components.minute, minutes > 1 {
            return "TimestampMinuteFullLabel".localise([minutes])
            
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
    
    func style(_ font:CGFloat, kerning:CGFloat) -> some View {
        self.modifier(ViewTextStyle(size: font, kerning: kerning))

    }

}

extension UserDefaults {
    static let changed = PassthroughSubject<AppDefaultsKeys, Never>()

    static var main:UserDefaults {
        return UserDefaults()
        
    }
    
    static var list:Array<AppDefaultsKeys> {
        return UserDefaults.main.dictionaryRepresentation().keys.compactMap({ AppDefaultsKeys(rawValue:$0) })
        
    }

    static func save(_ key:AppDefaultsKeys, value:Any?) {
        self.save(string: key.rawValue, value: value)
        
    }
    
    static func remove(_ matches:String) {
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.contains(matches) {
                self.save(string: key, value: nil)
                
                #if MAINTARGET
                    print("\n\n💾 Reset '\(key)'\n\n")

                #endif
                
            }

        }
        
    }

    static func save(string key:String, value:Any?, debug:Bool = false) {
        if let value = value {
            main.set(Date(), forKey: "\(key)_timestamp")
            main.set(value, forKey: key)
            main.synchronize()
            
            if let system = AppDefaultsKeys(rawValue: key) {
                changed.send(system)

            }

            if debug {
                print("\n\n💾 Saved \(value) to '\(key)'\n\n")
                
            }
            
        }
        else {
            main.removeObject(forKey: key)
            main.synchronize()

            if let system = AppDefaultsKeys(rawValue: key) {
                changed.send(system)

            }

        }
        
    }
    
    static func timestamp(_ key:AppDefaultsKeys) -> Date? {
        if let timetamp = UserDefaults.main.object(forKey: "\(key.rawValue)_timestamp") as? Date {
            return timetamp
        }
        
        return nil
        
    }
    
    static func sync(_ key: String, value: Any?) {
        let store = NSUbiquitousKeyValueStore.default
        if let value = value {
            store.set(value, forKey: key)
        } else {
            store.removeObject(forKey: key)
        }
        store.synchronize()
    }
    
    static func cloud<T>(_ key: String) -> T? {
        return NSUbiquitousKeyValueStore.default.object(forKey: key) as? T
    }
    
}

extension CodingUserInfoKey {
    static let device = CodingUserInfoKey(rawValue: "device")!
    static let connected = CodingUserInfoKey(rawValue: "connected")!

}
