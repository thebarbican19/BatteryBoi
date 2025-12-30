//
//  BBUpdateManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/25/23.
//

import Foundation
import AppKit
import Sparkle
import Combine

struct UpdateVersionObject: Codable {
    var formatted: String
    var numerical: Double

}

struct UpdatePayloadObject: Equatable {
    static func == (lhs: UpdatePayloadObject, rhs: UpdatePayloadObject) -> Bool {
        return lhs.id == rhs.id

    }

    var id: String
    var name: String
    var version: UpdateVersionObject
    var binary: String?
    var cached: Bool?
    var ignore: Bool = false

}

enum UpdateStateType {
    case idle
    case checking
    case updating
    case failed
    case completed

    public func subtitle(_ last: Date?, version: String? = nil) -> String {
        switch self {
            case .idle: return "UpdateStatusIdleLabel".localise([last?.formatted ?? "TimestampNeverLabel".localise()])
            case .checking: return "UpdateStatusCheckingLabel".localise()
            case .updating: return "UpdateStatusNewLabel".localise([version ?? ""])
            case .failed: return "UpdateStatusEmptyLabel".localise()
            case .completed: return "UpdateStatusEmptyLabel".localise()

        }

    }

}

public class UpdateManager: NSObject, SPUUpdaterDelegate, ObservableObject {
    static var shared = UpdateManager()

    @Published var state: UpdateStateType = .completed
    @Published var available: UpdatePayloadObject?
    @Published var checked: Date?

    private let driver = SPUStandardUserDriver(hostBundle: Bundle.main, delegate: nil)

    private var updates = Set<AnyCancellable>()
    private var updater: SPUUpdater?

    override init() {
        super.init()

        self.updater = SPUUpdater(hostBundle: Bundle.main, applicationBundle: Bundle.main, userDriver: self.driver, delegate: self)
        self.updater?.automaticallyChecksForUpdates = true
        self.updater?.automaticallyDownloadsUpdates = true
        self.updater?.updateCheckInterval = 60.0 * 60.0 * 12

        do {
            try self.updater?.start()

        }
        catch {

        }

        self.$state.delay(for: 5, scheduler: RunLoop.main).sink() { newValue in
            if newValue == .completed || newValue == .failed {
                self.state = .idle

            }

        }.store(in: &updates)

        self.checked = self.updater?.lastUpdateCheckDate

    }

    deinit {
        self.updates.forEach { $0.cancel() }

    }

    public func updateCheck() {
        self.updater?.checkForUpdatesInBackground()
        self.state = .checking

    }

    func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock immediateInstallHandler: @escaping () -> Void) -> Bool {
        immediateInstallHandler()
        return true

    }

    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem, untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
        return false

    }

    func updaterShouldDownloadReleaseNotes(_ updater: SPUUpdater) -> Bool {
        return true

    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        if let title = item.title {
            let id = item.propertiesDictionary["id"] as! String
            let build = item.propertiesDictionary["sparkle:shortVersionString"] as? Double ?? 0.0
            let version: UpdateVersionObject = .init(formatted: title, numerical: build)

            DispatchQueue.main.async {
                self.available = .init(id: id, name: title, version: version)
                self.state = .completed
                self.checked = self.updater?.lastUpdateCheckDate

            }

        }
        else {
            DispatchQueue.main.async {
                self.state = .failed
                self.checked = self.updater?.lastUpdateCheckDate

            }

        }

    }

    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        print("update could not get update", error)

    }

    func updater(_ updater: SPUUpdater, failedToDownloadAppcastWithError error: Error) {
        print("update could not get appcast", error)

    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        print("✅ Version \(String(describing: Bundle.main.infoDictionary?["CFBundleShortVersionString"])) is the Latest")

        DispatchQueue.main.async {
            self.available = nil
            self.state = .completed

        }

    }

    func updater(_ updater: SPUUpdater, willShowModalAlert alert: NSAlert) {

    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        if let error = error as NSError? {
            if error.code == 4005 {
                self.state = .completed

            }

        }

    }

    public var updateVersion: String {
        get {
            if let version = UserDefaults.main.object(forKey: SystemDefaultsKeys.versionCurrent.rawValue) as? String {
                return version

            }
            else {
                self.updateVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String

            }

            return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String

        }

        set {
            UserDefaults.save(.versionCurrent, value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)

        }

    }
    
}

@objc public class UpdateDriver: NSObject, SPUUserDriver {
    public func show(_ request: SPUUpdatePermissionRequest) async -> SUUpdatePermissionResponse {
        return SUUpdatePermissionResponse(automaticUpdateChecks: true, sendSystemProfile: true)

    }

    public func showUserInitiatedUpdateCheck(cancellation: @escaping () -> Void) {

    }

    public func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState) async -> SPUUserUpdateChoice {
        return .install

    }

    public func showUpdateReleaseNotes(with downloadData: SPUDownloadData) {

    }

    public func showUpdateReleaseNotesFailedToDownloadWithError(_ error: Error) {

    }

    public func showUpdateNotFoundWithError(_ error: Error, acknowledgement: @escaping () -> Void) {

    }

    public func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        print("error", error)
    }

    public func showDownloadInitiated(cancellation: @escaping () -> Void) {

    }

    public func showDownloadDidReceiveExpectedContentLength(_ expectedContentLength: UInt64) {

    }

    public func showDownloadDidReceiveData(ofLength length: UInt64) {

    }

    public func showDownloadDidStartExtractingUpdate() {

    }

    public func showExtractionReceivedProgress(_ progress: Double) {

    }

    public func showReadyToInstallAndRelaunch() async -> SPUUserUpdateChoice {
        return .install

    }

    public func showInstallingUpdate(withApplicationTerminated applicationTerminated: Bool, retryTerminatingApplication: @escaping () -> Void) {

    }

    public func showUpdateInstalledAndRelaunched(_ relaunched: Bool, acknowledgement: @escaping () -> Void) {

    }

    public func showUpdateInFocus() {

    }

    public func dismissUpdateInstallation() {

    }
}
