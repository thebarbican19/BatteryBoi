//
//  BBAppManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/9/23.
//

import Foundation
import Combine
import SwiftUI
import SwiftData
import CloudKit
import CoreBluetooth

#if os(iOS)
    import Deviice
#endif

public class AppManager: ObservableObject {
    public static var shared = AppManager()

    @Published public var sessionid: UUID = UUID()
    @Published public var counter = 0
    @Published var devices = Array<AppDeviceObject>()
    @Published var selected: AppDeviceObject? = nil
    @Published public var updated: Date? = nil
    @Published public var distribution: AppDistribution = .direct

    #if os(macOS)
        @Published public var menu: AppMenuView = .devices
        @Published public var alert: AppAlertTypes? = nil

    #endif

    #if os(iOS)
        @Published public var hasMacDevice: Bool = false
    #endif

    private var updates = Set<AnyCancellable>()
    public init() {
        self.appUsageTracker()

        if let receipt = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: receipt.path) {
            self.distribution = .appstore

        }

        $devices.receive(on: DispatchQueue.global()).debounce(for: .seconds(3), scheduler: RunLoop.main).sink { _ in
            self.appStoreDevice()

        }.store(in: &updates)

        #if os(macOS)
            Timer.publish(every: 300, on: .main, in: .common).autoconnect().sink { [weak self] _ in
                self?.appStoreDevice()
            }.store(in: &updates)
        #endif

        self.setupCLISymlink()

    }

    deinit {
        self.updates.forEach { $0.cancel() }

    }
      
    public var appInstalled: Date {
        if let date = UserDefaults.main.object(forKey: AppDefaultsKeys.versionInstalled.rawValue) as? Date {
            return date

        }
        else {
            UserDefaults.save(.versionInstalled, value: Date())

            self.createCLISymlink()

            return Date()

        }

    }

    private func createCLISymlink() {
        #if os(macOS)
        DispatchQueue.global(qos: .background).async {
            self.setupCLISymlink()
        }
        #endif
    }

    public func setupCLISymlink() {
        #if os(macOS)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.createSymlinkIfNeeded()
        }
        #endif
    }

    private func createSymlinkIfNeeded() {
        #if os(macOS)
        let fileManager = FileManager.default
        let possibleSymlinkPaths = [
            "/usr/local/bin/cliboi",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin/cliboi").path
        ]

        let possibleCliPaths = [
            Bundle.main.bundlePath + "/Contents/SharedSupport/cliboi",
            "/Applications/BatteryBoi.app/Contents/SharedSupport/cliboi",
            Bundle.main.bundlePath + "/Contents/MacOS/cliboi",
            "/Applications/BatteryBoi.app/Contents/MacOS/cliboi",
            Bundle.main.bundlePath + "/Contents/Executables/cliboi",
            "/Applications/BatteryBoi.app/Contents/Executables/cliboi"
        ]

        var foundCLI: String? = nil
        for cliPath in possibleCliPaths {
            if fileManager.fileExists(atPath: cliPath) {
                foundCLI = cliPath
                break
            }
        }

        guard let cliBinaryPath = foundCLI else {
            return
        }

        for symlinkPath in possibleSymlinkPaths {
            if fileManager.fileExists(atPath: symlinkPath) {
                self.ensureLocalBinInPath()
                return
            }

            do {
                let symlinkDir = (symlinkPath as NSString).deletingLastPathComponent
                if !fileManager.fileExists(atPath: symlinkDir) {
                    try fileManager.createDirectory(atPath: symlinkDir, withIntermediateDirectories: true, attributes: nil)
                }

                try fileManager.createSymbolicLink(atPath: symlinkPath, withDestinationPath: cliBinaryPath)
                self.ensureLocalBinInPath()
                return
            }
            catch {
                continue
            }
        }

        #endif
    }

    private func ensureLocalBinInPath() {
        #if os(macOS)
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser.path
        let localBinPath = homeDir + "/.local/bin"
        let shellConfigFiles = [
            homeDir + "/.zshrc",
            homeDir + "/.bash_profile",
            homeDir + "/.bashrc"
        ]

        let pathExportLine = "export PATH=\"" + localBinPath + ":$PATH\""

        for configFile in shellConfigFiles {
            guard fileManager.fileExists(atPath: configFile) == true else {
                continue
            }

            do {
                let content = try String(contentsOfFile: configFile, encoding: .utf8)
                if content.contains(localBinPath) {
                    continue
                }

                let newContent = content.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n" + pathExportLine + "\n"
                try newContent.write(toFile: configFile, atomically: true, encoding: .utf8)
            }
            catch {
                continue
            }
        }
        #endif
    }
    
    public func appUsageTracker() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!

        if let latest = self.appUsage {
            let last = calendar.dateComponents([.year, .month, .day], from: latest.timestamp)
            let current = calendar.dateComponents([.year, .month, .day], from: Date())

            if let lastDate = calendar.date(from: last), let currentDate = calendar.date(from: current) {
                if currentDate > lastDate {
                    self.appUsage = .init(day: latest.day + 1, timestamp: Date())

                }

            }

        }
        else {
            self.appUsage = .init(day: 1, timestamp: Date())

        }

    }

    public var appUsage: AppUsage? {
        get {
            let days = UserDefaults.main.object(forKey: AppDefaultsKeys.usageDay.rawValue) as? Int
            let timestamp = UserDefaults.main.object(forKey: AppDefaultsKeys.usageTimestamp.rawValue) as? Date

            if let days = days, let timestamp = timestamp {
                return .init(day: days, timestamp: timestamp)

            }

            return nil

        }

        set {
            if let newValue = newValue {
                UserDefaults.save(.usageDay, value: newValue.day)
                UserDefaults.save(.usageTimestamp, value: newValue.timestamp)

            }

        }

    }

    private func appListDevices() {
        if let context = self.appStorageContext() {
            let descriptor = FetchDescriptor<DevicesObject>()

            do {
                let list = try context.fetch(descriptor)
                let mapped: [AppDeviceObject] = list.compactMap({ .init($0) })

                DispatchQueue.main.async {
                    self.devices = mapped

                    #if os(iOS)
                        self.hasMacDevice = self.checkForMacDevices(mapped)
                    #endif

                }

            }
            catch {

            }

        }

    }

    func appStoreDevice(_ device: AppDeviceObject? = nil) {
        if let context = self.appStorageContext() {
            let deviceName = device?.name ?? "system"

            if let match = AppDeviceObject.match(device, context: context) {
                let matchId: UUID? = match.id
                var descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == matchId })
                descriptor.fetchLimit = 1

                do {
                    let fetchStart = Date()
                    if let existing = try context.fetch(descriptor).first {
                        let fetchTime = Date().timeIntervalSince(fetchStart)
                        existing.refreshedOn = Date()

                        if existing.serial?.isEmpty == true {
                            existing.serial = device?.profile.serial

                        }

                        if existing.name?.isEmpty == true {
                            existing.name = device?.name

                        }

                        if existing.address?.isEmpty == true {
                            existing.address = device?.address

                        }

                        if let device = device, let type = AppDeviceTypes.type(device.profile.model) {
                            existing.subtype = type.category.rawValue
                            existing.type = type.rawValue

                        }

                        if existing.vendor?.isEmpty == true {
                            existing.vendor = device?.profile.vendor

                        }

                        if let favourite = device?.favourite {
                            existing.favourite = favourite

                        }

                        if let notifications = device?.notifications {
                            existing.notifications = notifications

                        }

                        if let id = device?.id {
                            existing.id = id

                        }

                        let saveStart = Date()
                        try context.save()
                        let saveTime = Date().timeIntervalSince(saveStart)

                        if saveTime > 1.0 {

                        }

                    }

                }
                catch {

                }

            }
            else {
                let store = DevicesObject()
                store.addedOn = Date()
                store.refreshedOn = Date()
                store.order = self.devices.count + 1
                store.id = UUID()
                store.notifications = true
                store.hidden = false

                if let device = device {
                    let type = AppDeviceTypes.type(device.profile.model)

                    store.primary = false
                    store.name = device.name
                    store.model = device.profile.model
                    store.serial = device.profile.serial
                    store.vendor = device.profile.vendor
                    store.type = type?.category.rawValue
                    store.subtype = type?.rawValue
                    store.address = nil
                    store.owner = self.appDevice(nil, context: context)?.id

                }
                else {
                    if UserDefaults.main.object(forKey: AppDefaultsKeys.deviceIdentifyer.rawValue) == nil {
                        store.model = AppDeviceTypes.model
                        store.os = AppDeviceTypes.os
                        store.subtype = AppDeviceTypes.type.rawValue
                        store.type = AppDeviceTypes.type.category.rawValue
                        store.primary = true
                        store.vendor = "Apple Inc"
                        store.product = AppDeviceTypes.name(false)
                        store.serial = AppDeviceTypes.serial
                        store.address = nil
                        store.name = AppDeviceTypes.name(true)

                        UserDefaults.save(.deviceIdentifyer, value: store.id?.uuidString)
                        UserDefaults.save(.deviceCreated, value: Date())

                    }

                }

                if store.model?.isEmpty == false || store.name?.isEmpty == false {
                    do {
                        context.insert(store)
                        let saveStart = Date()
                        try context.save()
                        let saveTime = Date().timeIntervalSince(saveStart)

                        if saveTime > 1.0 {

                        }

                    }
                    catch {

                    }

                }
                else {

                }

            }

        }

    }

    private func appDevice(_ device: AppDeviceObject?, context: ModelContext) -> DevicesObject? {
        if let match = AppDeviceObject.match(device, context: context) {
            let matchId: UUID? = match.id
            var descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate { $0.id == matchId })
            descriptor.fetchLimit = 1

            if let device = try? context.fetch(descriptor).first {
                return device

            }

        }

        return nil

    }

    public func appStorageContext() -> ModelContext? {
        if let container = CloudManager.container?.container {
            if CloudManager.shared.syncing == .completed {
                let context = ModelContext(container)
                context.autosaveEnabled = true

                return context

            }
            else {

            }

        }
        else {

        }

        return nil

    }

    func appDestoryEntity(_ type: CloudEntityType) {
        if let context = self.appStorageContext() {
            do {
                switch type {
                    case .devices:
                        let descriptor = FetchDescriptor<DevicesObject>()
                        let items = try context.fetch(descriptor)
                        for item in items {
                            context.delete(item)
                        }
                    case .events:
                        let descriptor = FetchDescriptor<BatteryObject>()
                        let items = try context.fetch(descriptor)
                        for item in items {
                            context.delete(item)
                        }
                }
                try context.save()

            }
            catch {

            }

        }

    }

    #if os(macOS)
        public func appToggleMenu(_ animate: Bool) {
            if animate {
                withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 1.0)) {
                    switch self.menu {
                        case .devices: self.menu = .settings
                        default: self.menu = .devices

                    }
                }

            }
            else {
                switch self.menu {
                    case .devices: self.menu = .settings
                    default: self.menu = .devices

                }

            }

        }

    #endif

    #if os(iOS)
        private func checkForMacDevices(_ devices: [AppDeviceObject]) -> Bool {
            return devices.contains(where: { device in
                guard device.connectivity == .system else {
                    return false
                }

                guard let subtype = device.profile.subtype else {
                    return false
                }

                guard let deviceType = AppDeviceTypes(rawValue: subtype) else {
                    return false
                }

                return deviceType.mac
            })
        }

        public var activeMacDevices: [AppDeviceObject] {
            let recentThreshold = Date(timeIntervalSinceNow: -600)

            return devices.filter { device in
                guard device.connectivity == .system else {
                    return false
                }

                guard let subtype = device.profile.subtype else {
                    return false
                }

                guard let deviceType = AppDeviceTypes(rawValue: subtype) else {
                    return false
                }

                guard deviceType.mac else {
                    return false
                }

                if let refreshed = device.refreshed, refreshed > recentThreshold {
                    return true
                }

                return false
            }
        }

        public var hasActiveMac: Bool {
            return activeMacDevices.isEmpty == false
        }
    #endif

}