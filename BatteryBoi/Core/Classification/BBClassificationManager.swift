//
//  BBClassificationManager.swift
//  BatteryBoi
//
//  Created by Claude Code on 01/05/25.
//

import Foundation
import Combine
import SwiftData

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

#if os(macOS) || os(iOS)
import FoundationModels
#endif

public class ClassificationManager: ObservableObject {
    static let shared = ClassificationManager()

    private let logger = LogManager.shared
    private let modelVersion = "1.0.0"
    private var classificationCache: [String: ClassificationResult] = [:]
    private let cacheQueue = DispatchQueue(label: "com.batteryboi.classification.cache", attributes: .concurrent)

    @Published var analytics = ClassificationAnalytics()
    private let analyticsQueue = DispatchQueue(label: "com.batteryboi.classification.analytics", attributes: .concurrent)

    private init() {
        logger.logInfo("ClassificationManager initialized")
        classifyLoadAnalytics()
    }

    func classifyDevice(model: String, vendor: String? = nil, appearance: String? = nil, hardware: String? = nil, name: String? = nil) async -> ClassificationResult {
        let cacheKey = classifyCacheKey(model: model, vendor: vendor, appearance: appearance)

        if let cached = classifyGetCachedResult(cacheKey) {
            logger.logDebug("Using cached classification for: \(model)")
            return cached
        }

        let result: ClassificationResult

        if #available(macOS 26.0, iOS 26.0, *) {
            if let aiResult = await classifyFoundationModels(model: model, vendor: vendor, appearance: appearance, hardware: hardware, name: name) {
                result = aiResult
            }
            else {
                result = classifyHeuristics(model: model, vendor: vendor, appearance: appearance, hardware: hardware, name: name)
                classifyRecordMetric(result, usingHeuristics: true)
            }
        }
        else {
            result = classifyHeuristics(model: model, vendor: vendor, appearance: appearance, hardware: hardware, name: name)
            classifyRecordMetric(result, usingHeuristics: true)
        }

        if result.category != .unknown {
            classifyRecordMetric(result, usingHeuristics: false)
        }

        classifySetCachedResult(cacheKey, result: result)
        return result
    }

    @available(macOS 26.0, iOS 26.0, *)
    private func classifyFoundationModels(model: String, vendor: String?, appearance: String?, hardware: String?, name: String?) async -> ClassificationResult? {
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            return ()
        }

        defer {
            timeoutTask.cancel()
        }

        logger.logDebug("Classifying device with Foundation Models: \(model)")

        return await classifyParseLLMResponse(model: model, vendor: vendor, appearance: appearance)
    }

    private func classifyHeuristics(model: String, vendor: String?, appearance: String?, hardware: String?, name: String?) -> ClassificationResult {
        logger.logDebug("Classifying device with heuristics: \(model)")

        if let result = classifyAppearanceCode(appearance) {
            return result
        }

        if let result = classifyVendorModel(model: model, vendor: vendor) {
            return result
        }

        if let result = classifyExistingLogic(model: model) {
            return result
        }

        return ClassificationResult(category: .unknown, confidence: 0.3, summary: "Device type could not be determined from available information.", reasoning: "No matching classification rules for model: \(model)")
    }

    private func classifyAppearanceCode(_ appearance: String?) -> ClassificationResult? {
        guard let appearance = appearance, let hex = Int(appearance, radix: 16) else {
            return nil
        }

        let appearanceClassifications: [Int: (category: AppDeviceCategory, confidence: Double, summary: String)] = [
            0x03C2: (.mouse, 0.95, "Bluetooth mouse device for computer input."),
            0x03C1: (.keyboard, 0.95, "Bluetooth keyboard for computer input."),
            0x03C4: (.gamepad, 0.90, "Bluetooth game controller or gamepad."),
            0x0841: (.headphones, 0.90, "Bluetooth headphones for audio output."),
            0x0842: (.headphones, 0.90, "Bluetooth headphones for audio output."),
            0x0843: (.earbuds, 0.92, "Bluetooth earbuds for wireless audio."),
            0x0844: (.earbuds, 0.92, "Bluetooth earbuds for wireless audio."),
            0x0845: (.speaker, 0.88, "Bluetooth speaker for audio playback."),
            0x0846: (.speaker, 0.88, "Bluetooth speaker for audio playback."),
            0x0847: (.speaker, 0.88, "Bluetooth speaker for audio playback."),
        ]

        if let (category, confidence, summary) = appearanceClassifications[hex] {
            return ClassificationResult(category: category, confidence: confidence, summary: summary, reasoning: "Matched Bluetooth appearance code: 0x\(String(hex, radix: 16))")
        }

        return nil
    }

    private func classifyVendorModel(model: String, vendor: String?) -> ClassificationResult? {
        let lowerModel = model.lowercased()
        let lowerVendor = vendor?.lowercased() ?? ""

        let vendorPatterns: [(vendor: String, pattern: String, category: AppDeviceCategory, confidence: Double, summary: String)] = [
            ("apple", "magicmouse", .mouse, 0.95, "Apple Magic Mouse for Mac input control."),
            ("apple", "airpods", .earbuds, 0.98, "Apple AirPods wireless earbuds."),
            ("apple", "pencil", .stylus, 0.95, "Apple Pencil for iPad input."),
            ("apple", "watch", .watch, 0.97, "Apple Watch smartwatch device."),
            ("nut", "nut", .tracker, 0.92, "Nut Smart Tracker for locating items like keys and wallets."),
            ("tile", "", .tracker, 0.90, "Tile Bluetooth tracker for finding items."),
            ("logitech", "mx", .mouse, 0.90, "Logitech MX series mouse."),
            ("logitech", "keyboard", .keyboard, 0.90, "Logitech Bluetooth keyboard."),
            ("sony", "wh", .headphones, 0.88, "Sony WH series wireless headphones."),
            ("bose", "", .headphones, 0.85, "Bose Bluetooth headphones or speakers."),
            ("samsung", "buds", .earbuds, 0.88, "Samsung Galaxy Buds earbuds."),
            ("microsoft", "xbox", .gamepad, 0.95, "Microsoft Xbox wireless controller."),
            ("8bitdo", "", .gamepad, 0.90, "8BitDo wireless game controller."),
        ]

        for pattern in vendorPatterns {
            if lowerVendor.contains(pattern.vendor) || lowerModel.contains(pattern.vendor) {
                if pattern.pattern.isEmpty || lowerModel.contains(pattern.pattern) {
                    return ClassificationResult(category: pattern.category, confidence: pattern.confidence, summary: pattern.summary, reasoning: "Matched vendor/model pattern: \(pattern.vendor) + \(pattern.pattern)")
                }
            }
        }

        return nil
    }

    private func classifyExistingLogic(model: String) -> ClassificationResult? {
        if let type = AppDeviceTypes.type(model) {
            let category = type.category
            let confidence = 0.85
            let deviceName = AppDeviceTypes.name() ?? "Apple device"
            let summary = "\(deviceName) (\(model))"

            return ClassificationResult(category: category, confidence: confidence, summary: summary, reasoning: "Matched Apple device type from existing classification logic")
        }

        return nil
    }

    @available(macOS 26.0, iOS 26.0, *)
    private func classifyParseLLMResponse(model: String, vendor: String?, appearance: String?) async -> ClassificationResult? {
        logger.logDebug("Foundation Models API pending - using heuristics fallback for: \(model)")
        return nil
    }

    private func classifyParseJSON(_ text: String) -> ClassificationResult? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = trimmedText.data(using: .utf8) else {
            logger.logWarning("Could not encode response as UTF8")
            return nil
        }

        do {
            if let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let categoryStr = jsonData["category"] as? String == "default" ? "unknown" : (jsonData["category"] as? String ?? "unknown")
                let confidence = jsonData["confidence"] as? Double ?? 0.5
                let summary = jsonData["summary"] as? String ?? "Device classification pending"
                let reasoning = jsonData["reasoning"] as? String

                if let category = AppDeviceCategory(rawValue: categoryStr) {
                    return ClassificationResult(category: category, confidence: max(0.0, min(1.0, confidence)), summary: summary, reasoning: reasoning)
                }
            }

            logger.logWarning("Could not parse Foundation Models JSON response")
            return nil
        }
        catch {
            logger.logWarning("JSON parsing error: \(error.localizedDescription)")
            return nil
        }
    }

    private func classifyPrompt(model: String, vendor: String?, appearance: String?, hardware: String?, name: String?) -> String {
        return """
        You are a Bluetooth device classifier. Given the following metadata, classify the device type and provide a summary.

        METADATA:
        - Model: \(model)
        - Vendor: \(vendor ?? "Unknown")
        - Bluetooth Appearance: \(appearance ?? "Unknown")
        - Hardware: \(hardware ?? "Unknown")
        - Device Name: \(name ?? "Unknown")

        AVAILABLE CATEGORIES: desktop, laptop, tablet, smartphone, mouse, headphones, gamepad, speaker, keyboard, tracker, watch, earbuds, stylus, camera, remote, sensor, healthDevice, unknown, other

        REQUIRED OUTPUT (JSON):
        {
          "category": "<one of the categories above>",
          "confidence": <0.0-1.0>,
          "summary": "<1-2 sentence description>",
          "reasoning": "<brief explanation>"
        }

        Rules:
        1. Be conservative - use 'unknown' if genuinely unclear
        2. Confidence should reflect certainty (0.9+ for obvious devices like "Apple Magic Mouse")
        3. Summary should be user-friendly and explain what the device does
        4. Consider vendor reputation (Apple, Samsung = high confidence)
        """
    }

    private func classifyCacheKey(model: String, vendor: String?, appearance: String?) -> String {
        return "\(model)_\(vendor ?? "")_\(appearance ?? "")"
    }

    private func classifyGetCachedResult(_ key: String) -> ClassificationResult? {
        return cacheQueue.sync {
            classificationCache[key]
        }
    }

    private func classifySetCachedResult(_ key: String, result: ClassificationResult) {
        cacheQueue.async(flags: .barrier) {
            self.classificationCache[key] = result
        }
    }

    func classifyExistingDevices() async {
        logger.logInfo("Starting retroactive classification of existing devices")

        let progressKey = "bb_classification_progress"
        let completedCountKey = "bb_classification_completed"
        let totalCountKey = "bb_classification_total"

        guard let context = try? ModelContext(ModelContainer(for: DevicesObject.self)) else {
            logger.logWarning("Could not create ModelContext for retroactive classification")
            return
        }

        do {
            let descriptor = FetchDescriptor<DevicesObject>(predicate: #Predicate<DevicesObject> { device in
                device.aiCategory == nil
            })
            let unclassifiedDevices = try context.fetch(descriptor)

            guard unclassifiedDevices.isEmpty == false else {
                logger.logInfo("All devices already classified")
                UserDefaults.standard.set(true, forKey: progressKey)
                return
            }

            UserDefaults.standard.set(false, forKey: progressKey)
            UserDefaults.standard.set(0, forKey: completedCountKey)
            UserDefaults.standard.set(unclassifiedDevices.count, forKey: totalCountKey)

            logger.logInfo("Found \(unclassifiedDevices.count) unclassified devices")

            for device in unclassifiedDevices {
                let result = await classifyDevice(model: device.model ?? "", vendor: device.vendor, appearance: device.apperance, hardware: nil, name: device.name)

                device.aiCategory = result.category.rawValue
                device.aiConfidence = result.confidence
                device.aiSummary = result.summary
                device.aiClassifiedOn = Date()
                device.aiVersion = modelVersion

                do {
                    try context.save()
                    let completed = UserDefaults.standard.integer(forKey: completedCountKey) + 1
                    UserDefaults.standard.set(completed, forKey: completedCountKey)
                    let progress = Double(completed) / Double(unclassifiedDevices.count)
                    logger.logDebug("Classification progress: \(String(format: "%.1f%%", progress * 100))")
                }
                catch {
                    logger.logWarning("Error saving classified device: \(error.localizedDescription)")
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            UserDefaults.standard.set(true, forKey: progressKey)
            logger.logInfo("Retroactive classification completed")
        }
        catch {
            logger.logWarning("Error fetching unclassified devices: \(error.localizedDescription)")
        }
    }

    func classifyClearCache() {
        cacheQueue.async(flags: .barrier) {
            self.classificationCache.removeAll()
        }
        logger.logInfo("Classification cache cleared")
    }

    func classifyGetProgress() -> Double {
        let completedKey = "bb_classification_completed"
        let totalKey = "bb_classification_total"

        let completed = UserDefaults.standard.integer(forKey: completedKey)
        let total = UserDefaults.standard.integer(forKey: totalKey)

        guard total > 0 else { return 0.0 }
        return Double(completed) / Double(total)
    }

    func classifyIsComplete() -> Bool {
        return UserDefaults.standard.bool(forKey: "bb_classification_progress")
    }

    func classifyResetProgress() {
        UserDefaults.standard.set(false, forKey: "bb_classification_progress")
        UserDefaults.standard.set(0, forKey: "bb_classification_completed")
        UserDefaults.standard.set(0, forKey: "bb_classification_total")
    }

    private func classifyRecordMetric(_ result: ClassificationResult, usingHeuristics: Bool = false) {
        analyticsQueue.async(flags: .barrier) {
            self.analytics.totalClassifications += 1
            self.analytics.successfulClassifications += 1

            if usingHeuristics == true {
                self.analytics.heuristicFallbacks += 1
            }

            let confidenceBucket = String(format: "%.1f", result.confidence * 10) + "0%"
            self.analytics.confidenceDistribution[confidenceBucket, default: 0] += 1

            self.analytics.categoryDistribution[result.category.rawValue, default: 0] += 1

            let allConfidences = Array(self.analytics.confidenceDistribution.values).map { Double($0) }
            let totalConfidence = allConfidences.reduce(0, +) * result.confidence
            self.analytics.averageConfidence = totalConfidence / Double(max(1, self.analytics.totalClassifications))

            self.classifySaveAnalytics()

            let successRate = Double(self.analytics.successfulClassifications) / Double(max(1, self.analytics.totalClassifications))
            self.logger.logDebug("Classification Analytics - Total: \(self.analytics.totalClassifications) | Success Rate: \(String(format: "%.1f%%", successRate * 100)) | Avg Confidence: \(String(format: "%.2f", self.analytics.averageConfidence))")
        }
    }

    private func classifySaveAnalytics() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(analytics) {
            UserDefaults.standard.set(encoded, forKey: "bb_classification_analytics")
        }
    }

    private func classifyLoadAnalytics() {
        if let data = UserDefaults.standard.data(forKey: "bb_classification_analytics") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(ClassificationAnalytics.self, from: data) {
                analyticsQueue.async(flags: .barrier) {
                    self.analytics = decoded
                }
            }
        }
    }

    func classifyGetAnalyticsSummary() -> String {
        return """
        Classification Analytics Summary
        ================================
        Total Classifications: \(analytics.totalClassifications)
        Successful: \(analytics.successfulClassifications)
        Heuristic Fallbacks: \(analytics.heuristicFallbacks)
        Average Confidence: \(String(format: "%.2f", analytics.averageConfidence))

        Confidence Distribution:
        \(analytics.confidenceDistribution.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))

        Category Distribution:
        \(analytics.categoryDistribution.sorted { $0.key < $1.key }.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
        """
    }

    func classifyResetAnalytics() {
        analyticsQueue.async(flags: .barrier) {
            self.analytics = ClassificationAnalytics()
            UserDefaults.standard.removeObject(forKey: "bb_classification_analytics")
        }
        logger.logInfo("Classification analytics reset")
    }
}
