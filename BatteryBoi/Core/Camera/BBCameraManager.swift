import Foundation
import Combine
import AVFoundation
import AppKit

public class CameraManager: ObservableObject {
    static var shared = CameraManager()

    @Published var state: CameraPermissionState = .unknown
    @Published var isActive: Bool = false
    @Published var detectionMethod: CameraDetectionMethod = .unavailable

    private var updates = Set<AnyCancellable>()
    private let logger = LogManager.shared

    init() {
        Timer.publish(every: 10.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cameraCheckActivity()
            }
            .store(in: &updates)

        cameraCheckPermissions()
        cameraCheckActivity()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cameraRecheckActivity),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    public func cameraCheckPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        DispatchQueue.main.async {
            switch status {
                case .authorized: self.state = .allowed
                case .notDetermined: self.state = .undetermined
                case .denied: self.state = .denied
                case .restricted: self.state = .restricted
                @unknown default: self.state = .unknown
            }
        }
    }

    public func cameraCheckActivity() {
        var active = false
        var method: CameraDetectionMethod = .unavailable

        if self.state == .allowed {
            if let result = cameraCheckWithAVFoundation() {
                active = result
                method = .avfoundation
                logger.logDebug("Camera activity detected via AVFoundation: \(active)")
            }
        }

        if method == .unavailable {
            if let result = cameraCheckWithLsof() {
                active = result
                method = .lsof
                logger.logDebug("Camera activity detected via lsof: \(active)")
            }
        }

        DispatchQueue.main.async {
            let previousState = self.isActive
            self.isActive = active
            self.detectionMethod = method

            if previousState != active {
                if active == true {
                    self.logger.logInfo("Camera became active")
                }
                else {
                    self.logger.logInfo("Camera became inactive")
                }
            }
        }
    }

    private func cameraCheckWithAVFoundation() -> Bool? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        )

        guard discoverySession.devices.isEmpty == false else {
            logger.logDebug("No camera devices found")
            return false
        }

        return nil
    }

    private func cameraCheckWithLsof() -> Bool? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = []
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let cameraIndicators = ["AppleCamera", "VDC", "iSight", "CameraAgent"]

                for indicator in cameraIndicators {
                    if output.contains(indicator) {
                        logger.logDebug("Found camera indicator in lsof: \(indicator)")
                        return true
                    }
                }
            }

            return false
        }
        catch {
            logger.logError("lsof execution failed: \(error.localizedDescription)")
            return nil
        }
    }

    @objc private func cameraRecheckActivity() {
        cameraCheckPermissions()
        cameraCheckActivity()
    }

    deinit {
        updates.forEach { $0.cancel() }
    }
}
