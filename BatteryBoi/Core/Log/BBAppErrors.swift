//
//  BBAppErrors.swift
//  BatteryBoi
//
//  Created by Claude on 12/30/25.
//

import Foundation

public enum BBAppErrorCode: String, CaseIterable, Codable {
	case floridaMan = "FloridaMan"
	case soupKitchen = "SoupKitchen"
	case deskPop = "DeskPop"
	case porkSword = "PorkSword"
	case crabPeople = "CrabPeople"
	case foreverUnclean = "ForeverUnclean"
	case mcpoylesMilk = "McPoylesMilk"
	case looseSeal = "LooseSeal"
	case goldenGod = "GoldenGod"
	case milkSteak = "MilkSteak"
	case wickityWack = "WickiWack"
	case rickSanity = "RickSanity"
	case birdLaw = "BirdLaw"
	case charlieWork = "CharlieWork"
	case bobLoblaw = "BobLoblaw"
	case dolphinDivorce = "DolphinDivorce"
	case funkeMobile = "FunkeMobile"
	case smcFailure = "SMCFailure"
	case helperDead = "HelperDead"
	case bluetoothDrain = "BluetoothDrain"
	case cloudSync = "CloudSync"

	public var description: String {
		switch self {
			case .floridaMan: return "authentication credentials are missing"
			case .soupKitchen: return "syntax is all wrong"
			case .deskPop: return "external service error"
			case .porkSword: return "ingest error"
			case .crabPeople: return "value invalid or not allowed"
			case .foreverUnclean: return "not found"
			case .mcpoylesMilk: return "could not decode response data - it's not pure enough"
			case .looseSeal: return "Validation Error"
			case .goldenGod: return "Prompt Validation Error"
			case .milkSteak: return "Content could not be Enriched"
			case .wickityWack: return "invalid url"
			case .rickSanity: return "Saving Data Failed - you turned yourself into a pickle to avoid family counseling"
			case .birdLaw: return "LLM Error"
			case .charlieWork: return "Argument parsing error"
			case .bobLoblaw: return "Log export error"
			case .dolphinDivorce: return "Theme error"
			case .funkeMobile: return "Directory error"
			case .smcFailure: return "SMC communication error"
			case .helperDead: return "Privileged helper not responding"
			case .bluetoothDrain: return "Bluetooth scanning failure"
			case .cloudSync: return "iCloud sync failure"
		}
	}

	public var fatal: Bool {
		switch self {
			case .crabPeople: return true
			case .soupKitchen: return true
			case .mcpoylesMilk: return true
			case .porkSword: return true
			default: return false
		}
	}

	public var terminate: Bool {
		switch self {
			case .crabPeople: return true
			case .soupKitchen: return true
			default: return false
		}
	}

	public var icon: String {
		return self.fatal ? "🚨" : "❌"
	}
}

public struct BBAppError: Error, Equatable {
	public let code: BBAppErrorCode
	public let message: String
	public let reference: String?

	public init(_ code: BBAppErrorCode, message: String, reference: String? = nil) {
		self.message = message
		self.code = code
		self.reference = reference

		if code.fatal == true {
			#if DEBUG
			fatalError("Returned Error:\(code) - \(message)")
			#endif
		}

		print("\n\n\(code.icon) \(code.rawValue) - \(message) \nReference: #\(reference ?? "NOREF")\n\n")
	}

	public static func == (lhs: BBAppError, rhs: BBAppError) -> Bool {
		return lhs.code == rhs.code && lhs.message == rhs.message
	}
}

public enum BBAppDecodingError: Error, LocalizedError {
	case missingRequiredField(String)
	case invalidFieldType(field: String, expected: String, received: String)
	case invalidEnumValue(field: String, value: String, allowedValues: [String])
	case nestedObjectValidationFailed(field: String, underlyingError: Error)
	case arrayValidationFailed(field: String, index: Int, underlyingError: Error)
	case invalidFormat(field: String, format: String, example: String?)

	public var errorDescription: String? {
		switch self {
			case .missingRequiredField(let message): return message
			case .invalidFieldType(let field, let expected, let received): return "Field '\(field)' has incorrect type. Expected \(expected) but received \(received)."
			case .invalidEnumValue(let field, let value, let allowedValues): return "Field '\(field)' has invalid value '\(value)'. Allowed values: \(allowedValues.joined(separator: ", "))."
			case .nestedObjectValidationFailed(let field, let error): return "Field '\(field)' failed validation: \(error.localizedDescription)"
			case .arrayValidationFailed(let field, let index, let error): return "Field '\(field)' failed validation at index \(index): \(error.localizedDescription)"
			case .invalidFormat(let field, let format, let example):
				var message = "Field '\(field)' has invalid format. Expected format: \(format)."
				if let example = example {
					message += " Example: \(example)"
				}
				return message
		}
	}

	public var fieldName: String {
		switch self {
			case .missingRequiredField(let message): return message
			case .invalidFieldType(let field, _, _): return field
			case .invalidEnumValue(let field, _, _): return field
			case .nestedObjectValidationFailed(let field, _): return field
			case .arrayValidationFailed(let field, _, _): return field
			case .invalidFormat(let field, _, _): return field
		}
	}
}

extension KeyedDecodingContainer {
	func decodeRequired<T: Decodable>(_ type: T.Type, forKey key: Key, errorMessage: String) throws -> T {
		do {
			return try self.decode(type, forKey: key)
		} catch {
			throw BBAppDecodingError.missingRequiredField(errorMessage)
		}
	}

	func decodeRequiredEnum<T: RawRepresentable & Decodable>(_ type: T.Type, forKey key: Key, errorMessage: String, allowedValues: [String]) throws -> T where T.RawValue == String {
		do {
			return try self.decode(type, forKey: key)
		} catch DecodingError.dataCorrupted {
			if let rawValue = try? self.decode(String.self, forKey: key) {
				throw BBAppDecodingError.invalidEnumValue(field: errorMessage, value: rawValue, allowedValues: allowedValues)
			}
			throw BBAppDecodingError.missingRequiredField(errorMessage)
		} catch {
			throw BBAppDecodingError.missingRequiredField(errorMessage)
		}
	}

	func decodeNestedRequired<T: Decodable>(_ type: T.Type, forKey key: Key, errorMessage: String) throws -> T {
		do {
			return try self.decode(type, forKey: key)
		} catch let decodingError as BBAppDecodingError {
			throw decodingError
		} catch {
			throw BBAppDecodingError.nestedObjectValidationFailed(field: errorMessage, underlyingError: error)
		}
	}

	func decodeArrayRequired<T: Decodable>(_ type: [T].Type, forKey key: Key, errorMessage: String) throws -> [T] {
		do {
			return try self.decode(type, forKey: key)
		} catch let decodingError as BBAppDecodingError {
			throw decodingError
		} catch {
			throw BBAppDecodingError.arrayValidationFailed(field: errorMessage, index: 0, underlyingError: error)
		}
	}

	func decodeWithFormat<T: Decodable & LosslessStringConvertible>(_ type: T.Type, forKey key: Key, format: String, example: String? = nil) throws -> T {
		do {
			return try self.decode(type, forKey: key)
		} catch {
			throw BBAppDecodingError.invalidFormat(field: key.stringValue, format: format, example: example)
		}
	}
}
