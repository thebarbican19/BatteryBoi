//
//  BBHeartbeatConstants.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 1/3/26.
//

public enum HeartbeatDeviceType: String, CaseIterable {
	case iphone
	case ipad
	case mac
	case unknown
	
	static func from(_ raw: String) -> HeartbeatDeviceType {
		guard let appType = AppDeviceTypes(rawValue: raw) else {
			return .unknown
			
		}
		
		if appType.mac {
			return .mac
		}
		
		if appType == .iphone {
			return .iphone
			
		}
		
		if appType == .ipad {
			return .ipad
			
		}
		
		return .unknown
		
	}
	
}

public struct HeartbeatObject: Identifiable {
	public var id: String
	public var type: String
	public var name: String
	public var timestamp: TimeInterval
	public var os: String
	
	public var deviceType: HeartbeatDeviceType {
		return HeartbeatDeviceType.from(type)
		
	}
	
}
