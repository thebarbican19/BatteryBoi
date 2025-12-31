//
//  BBAppErrorTests.swift
//  BatteryBoiTests
//
//  Created by Claude on 12/30/25.
//

import XCTest
@testable import BatteryBoi

final class BBAppErrorTests: XCTestCase {

    func testAllErrorCodesHaveDescriptions() throws {
        for errorCode in BBAppErrorCode.allCases {
            XCTAssertFalse(errorCode.description.isEmpty, "\(errorCode.rawValue) should have a description")
        }
    }

    func testFatalErrorCodes() throws {
        XCTAssertTrue(BBAppErrorCode.soupKitchen.fatal, "soupKitchen should be fatal")
        XCTAssertTrue(BBAppErrorCode.crabPeople.fatal, "crabPeople should be fatal")
        XCTAssertTrue(BBAppErrorCode.mcpoylesMilk.fatal, "mcpoylesMilk should be fatal")
        XCTAssertTrue(BBAppErrorCode.porkSword.fatal, "porkSword should be fatal")

        XCTAssertFalse(BBAppErrorCode.floridaMan.fatal, "floridaMan should not be fatal")
        XCTAssertFalse(BBAppErrorCode.deskPop.fatal, "deskPop should not be fatal")
        XCTAssertFalse(BBAppErrorCode.rickSanity.fatal, "rickSanity should not be fatal")
    }

    func testTerminateErrorCodes() throws {
        XCTAssertTrue(BBAppErrorCode.soupKitchen.terminate, "soupKitchen should terminate")
        XCTAssertTrue(BBAppErrorCode.crabPeople.terminate, "crabPeople should terminate")

        XCTAssertFalse(BBAppErrorCode.mcpoylesMilk.terminate, "mcpoylesMilk should not terminate")
        XCTAssertFalse(BBAppErrorCode.porkSword.terminate, "porkSword should not terminate")
        XCTAssertFalse(BBAppErrorCode.floridaMan.terminate, "floridaMan should not terminate")
    }

    func testErrorIcons() throws {
        XCTAssertEqual(BBAppErrorCode.soupKitchen.icon, "🚨", "Fatal error should have 🚨 icon")
        XCTAssertEqual(BBAppErrorCode.crabPeople.icon, "🚨", "Fatal error should have 🚨 icon")
        XCTAssertEqual(BBAppErrorCode.mcpoylesMilk.icon, "🚨", "Fatal error should have 🚨 icon")
        XCTAssertEqual(BBAppErrorCode.porkSword.icon, "🚨", "Fatal error should have 🚨 icon")

        XCTAssertEqual(BBAppErrorCode.floridaMan.icon, "❌", "Non-fatal error should have ❌ icon")
        XCTAssertEqual(BBAppErrorCode.deskPop.icon, "❌", "Non-fatal error should have ❌ icon")
        XCTAssertEqual(BBAppErrorCode.rickSanity.icon, "❌", "Non-fatal error should have ❌ icon")
        XCTAssertEqual(BBAppErrorCode.smcFailure.icon, "❌", "Non-fatal error should have ❌ icon")
    }

    func testBatteryBoiSpecificErrorCodes() throws {
        XCTAssertEqual(BBAppErrorCode.smcFailure.description, "SMC communication error")
        XCTAssertEqual(BBAppErrorCode.helperDead.description, "Privileged helper not responding")
        XCTAssertEqual(BBAppErrorCode.bluetoothDrain.description, "Bluetooth scanning failure")
        XCTAssertEqual(BBAppErrorCode.cloudSync.description, "iCloud sync failure")
    }

    func testErrorCodeRawValues() throws {
        XCTAssertEqual(BBAppErrorCode.floridaMan.rawValue, "FloridaMan")
        XCTAssertEqual(BBAppErrorCode.soupKitchen.rawValue, "SoupKitchen")
        XCTAssertEqual(BBAppErrorCode.smcFailure.rawValue, "SMCFailure")
        XCTAssertEqual(BBAppErrorCode.helperDead.rawValue, "HelperDead")
    }

    func testBBAppErrorEquality() throws {
        let error1 = BBAppError(.floridaMan, message: "Test message", reference: "TestRef")
        let error2 = BBAppError(.floridaMan, message: "Test message", reference: "TestRef")
        let error3 = BBAppError(.floridaMan, message: "Different message", reference: "TestRef")
        let error4 = BBAppError(.deskPop, message: "Test message", reference: "TestRef")

        XCTAssertEqual(error1, error2, "Errors with same code and message should be equal")
        XCTAssertNotEqual(error1, error3, "Errors with different messages should not be equal")
        XCTAssertNotEqual(error1, error4, "Errors with different codes should not be equal")
    }

    func testBBAppDecodingErrorDescriptions() throws {
        let error1 = BBAppDecodingError.missingRequiredField("testField")
        XCTAssertEqual(error1.errorDescription, "testField")

        let error2 = BBAppDecodingError.invalidFieldType(field: "age", expected: "Int", received: "String")
        XCTAssertTrue(error2.errorDescription?.contains("has incorrect type") ?? false)

        let error3 = BBAppDecodingError.invalidEnumValue(field: "status", value: "invalid", allowedValues: ["active", "inactive"])
        XCTAssertTrue(error3.errorDescription?.contains("has invalid value") ?? false)

        let error4 = BBAppDecodingError.invalidFormat(field: "email", format: "email@domain.com", example: "test@example.com")
        XCTAssertTrue(error4.errorDescription?.contains("has invalid format") ?? false)
    }

    func testBBAppDecodingErrorFieldName() throws {
        let error1 = BBAppDecodingError.missingRequiredField("username")
        XCTAssertEqual(error1.fieldName, "username")

        let error2 = BBAppDecodingError.invalidFieldType(field: "age", expected: "Int", received: "String")
        XCTAssertEqual(error2.fieldName, "age")

        let error3 = BBAppDecodingError.invalidEnumValue(field: "status", value: "bad", allowedValues: ["good"])
        XCTAssertEqual(error3.fieldName, "status")
    }

    func testAllErrorCodesAreCodable() throws {
        for errorCode in BBAppErrorCode.allCases {
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()

            let encoded = try encoder.encode(errorCode)
            let decoded = try decoder.decode(BBAppErrorCode.self, from: encoded)

            XCTAssertEqual(errorCode, decoded, "\(errorCode.rawValue) should be codable")
        }
    }

    func testErrorCodeCount() throws {
        let totalCount = BBAppErrorCode.allCases.count

        XCTAssertEqual(totalCount, 21, "Should have 21 total error codes (17 from Orrivo + 4 BatteryBoi-specific)")
    }

    func testOrrivoErrorCodes() throws {
        let orrivoErrors: [BBAppErrorCode] = [
            .floridaMan, .soupKitchen, .deskPop, .porkSword, .crabPeople,
            .foreverUnclean, .mcpoylesMilk, .looseSeal, .goldenGod, .milkSteak,
            .wickityWack, .rickSanity, .birdLaw, .charlieWork, .bobLoblaw,
            .dolphinDivorce, .funkeMobile
        ]

        XCTAssertEqual(orrivoErrors.count, 17, "Should have 17 Orrivo error codes")

        for error in orrivoErrors {
            XCTAssertFalse(error.description.isEmpty, "\(error.rawValue) should have description")
        }
    }

    func testBatteryBoiErrorCodesAreNotFatal() throws {
        XCTAssertFalse(BBAppErrorCode.smcFailure.fatal, "smcFailure should not be fatal")
        XCTAssertFalse(BBAppErrorCode.helperDead.fatal, "helperDead should not be fatal")
        XCTAssertFalse(BBAppErrorCode.bluetoothDrain.fatal, "bluetoothDrain should not be fatal")
        XCTAssertFalse(BBAppErrorCode.cloudSync.fatal, "cloudSync should not be fatal")
    }

    func testBatteryBoiErrorCodesDoNotTerminate() throws {
        XCTAssertFalse(BBAppErrorCode.smcFailure.terminate, "smcFailure should not terminate")
        XCTAssertFalse(BBAppErrorCode.helperDead.terminate, "helperDead should not terminate")
        XCTAssertFalse(BBAppErrorCode.bluetoothDrain.terminate, "bluetoothDrain should not terminate")
        XCTAssertFalse(BBAppErrorCode.cloudSync.terminate, "cloudSync should not terminate")
    }
}
