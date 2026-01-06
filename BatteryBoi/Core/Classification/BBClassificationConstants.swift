//
//  BBClassificationConstants.swift
//  BatteryBoi
//
//  Created by Claude Code on 01/05/25.
//

import Foundation

struct ClassificationResult {
    let category: AppDeviceCategory
    let confidence: Double
    let summary: String
    let reasoning: String?
}

struct ClassificationAnalytics: Codable {
    var totalClassifications: Int = 0
    var successfulClassifications: Int = 0
    var heuristicFallbacks: Int = 0
    var averageConfidence: Double = 0.0
    var confidenceDistribution: [String: Int] = [:]
    var categoryDistribution: [String: Int] = [:]
}
