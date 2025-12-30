import Foundation

// MARK: - Mocks & Definitions needed for context if not importing module

class BluetoothManagerUtils {
    static func parseContinuityManufacturerData(_ data: Data) -> Int? {
        guard data.count >= 2 else {
            return nil
        }

        let companyID = UInt16(data[0]) | (UInt16(data[1]) << 8)
        guard companyID == 0x004C else {
            return nil
        }

        var offset = 2
        while offset < data.count {
            guard offset + 1 < data.count else {
                break
            }

            let type = data[offset]
            let length = Int(data[offset + 1])

            guard offset + 2 + length <= data.count else {
                break
            }

            if type == 0x07 && length >= 25 {
                let batteryLeft = data[offset + 13]
                let batteryRight = data[offset + 14]
                let batteryCase = data[offset + 15]

                let batteries = [batteryLeft, batteryRight, batteryCase].filter { $0 > 0 && $0 <= 100 }
                if batteries.isEmpty == false {
                    return Int(batteries.min() ?? 0)
                }
            }

            offset += 2 + length
        }

        return nil
    }
}

// MARK: - Test Runner

func assertNotNil(_ value: Any?, _ message: String) {
    if value == nil {
        print("❌ FAILED: \(message)")
        exit(1)
    }
}

func assertEqual<T: Equatable>(_ actual: T?, _ expected: T, _ message: String) {
    if actual != expected {
        print("❌ FAILED: \(message). Expected \(expected), got \(String(describing: actual))")
        exit(1)
    }
}

func assertNil(_ value: Any?, _ message: String) {
    if value != nil {
        print("❌ FAILED: \(message)")
        exit(1)
    }
}

class SystemIntegrationTests {
    func testCLIResourcesExist() {
        print("Running testCLIResourcesExist...")
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let scriptPath = currentPath + "/BatteryBoi/Other/Scripts/install.sh"
        
        if fileManager.fileExists(atPath: scriptPath) {
             print("✅ testCLIResourcesExist passed (File found at \(scriptPath)).")
        } else {
             print("❌ FAILED: install.sh not found at \(scriptPath)")
             exit(1)
        }
    }
    
    func testBluetoothModuleReturnsItemsFromContinuityData() {
        print("Running testBluetoothModuleReturnsItemsFromContinuityData...")
        var payload = Data([0x4C, 0x00, 0x07, 0x19])
        payload.append(Data(repeating: 0x00, count: 11)) // Padding 0-10 (11 bytes)
        payload.append(Data([0x32, 0x2D, 0x50])) // Indices 15, 16, 17 -> 50, 45, 80
        payload.append(Data(repeating: 0x00, count: 10))
        
        let batteryLevel = BluetoothManagerUtils.parseContinuityManufacturerData(payload)
        
        assertNotNil(batteryLevel, "Should parse valid continuity data")
        assertEqual(batteryLevel, 45, "Should return minimum battery level (45)")
        print("✅ testBluetoothModuleReturnsItemsFromContinuityData passed.")
    }
    
    func testBluetoothModuleReturnsNilForInvalidData() {
        print("Running testBluetoothModuleReturnsNilForInvalidData...")
        let invalidCompany = Data([0xFF, 0xFF, 0x07, 0x19] + [UInt8](repeating: 0, count: 30))
        assertNil(BluetoothManagerUtils.parseContinuityManufacturerData(invalidCompany), "Should return nil for invalid company")
        
        let shortData = Data([0x4C, 0x00, 0x07])
        assertNil(BluetoothManagerUtils.parseContinuityManufacturerData(shortData), "Should return nil for short data")
        print("✅ testBluetoothModuleReturnsNilForInvalidData passed.")
    }

    func runAll() {
        testCLIResourcesExist()
        testBluetoothModuleReturnsItemsFromContinuityData()
        testBluetoothModuleReturnsNilForInvalidData()
    }
}

let tests = SystemIntegrationTests()
tests.runAll()
print("\nAll integration tests passed successfully! 🎉")