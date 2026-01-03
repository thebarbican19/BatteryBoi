import XCTest
@testable import BatteryBoi

final class CameraManagerTests: XCTestCase {

    func testCameraManagerInitialization() {
        let manager = CameraManager.shared

        XCTAssertNotNil(manager.state)
        XCTAssertNotNil(manager.isActive)
        XCTAssertNotNil(manager.detectionMethod)
    }

    func testCameraPermissionStates() {
        let manager = CameraManager.shared
        manager.cameraCheckPermissions()

        let validStates: [CameraPermissionState] = [.allowed, .denied, .restricted, .undetermined, .unknown]
        XCTAssertTrue(validStates.contains(manager.state))
    }

    func testCameraActivityCheckDoesNotCrash() {
        let manager = CameraManager.shared

        XCTAssertNoThrow(manager.cameraCheckActivity())
    }

    func testDetectionMethodIsValid() {
        let manager = CameraManager.shared

        let validMethods: [CameraDetectionMethod] = [.avfoundation, .lsof, .unavailable]
        XCTAssertTrue(validMethods.contains(manager.detectionMethod))
    }

    func testCameraPermissionStateTitle() {
        XCTAssertEqual(CameraPermissionState.allowed.title, "Allowed")
        XCTAssertEqual(CameraPermissionState.denied.title, "Denied")
        XCTAssertEqual(CameraPermissionState.restricted.title, "Restricted")
        XCTAssertEqual(CameraPermissionState.undetermined.title, "Not Determined")
        XCTAssertEqual(CameraPermissionState.unknown.title, "Unknown")
    }

    func testDetectionMethodDescription() {
        XCTAssertEqual(CameraDetectionMethod.avfoundation.description, "AVFoundation")
        XCTAssertEqual(CameraDetectionMethod.lsof.description, "lsof (Fallback)")
        XCTAssertEqual(CameraDetectionMethod.unavailable.description, "Unavailable")
    }

    func testCameraManagerSingleton() {
        let manager1 = CameraManager.shared
        let manager2 = CameraManager.shared

        XCTAssertIdentical(manager1, manager2)
    }
}
