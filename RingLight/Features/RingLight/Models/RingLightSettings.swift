//
//  RingLightSettings.swift
//  RingLight
//
//  Shared preferences using Point-Free Sharing library
//

import Foundation
import Sharing

// MARK: - Settings Model

struct RingLightSettings: Sendable, Equatable {
    var isEnabled: Bool = false
    var width: Double = 160
    var feather: Double = 0.4
    var intensity: Double = 0.85
    var temperature: Double = 5200
    var cornerRadius: Double = 0
    var edgeInset: Double = 0
}

// MARK: - Codable Conformance (non-isolated)

extension RingLightSettings: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        self.width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 160
        self.feather = try container.decodeIfPresent(Double.self, forKey: .feather) ?? 0.4
        self.intensity = try container.decodeIfPresent(Double.self, forKey: .intensity) ?? 0.85
        self.temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ?? 5200
        self.cornerRadius = try container.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 0
        self.edgeInset = try container.decodeIfPresent(Double.self, forKey: .edgeInset) ?? 0
    }

    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.isEnabled, forKey: .isEnabled)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.feather, forKey: .feather)
        try container.encode(self.intensity, forKey: .intensity)
        try container.encode(self.temperature, forKey: .temperature)
        try container.encode(self.cornerRadius, forKey: .cornerRadius)
        try container.encode(self.edgeInset, forKey: .edgeInset)
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case width
        case feather
        case intensity
        case temperature
        case cornerRadius
        case edgeInset
    }
}

// MARK: - Individual Keys (Using AppStorage with proper delimiters)
// Note: Using colons as delimiters instead of periods for better KVO performance

extension SharedKey where Self == AppStorageKey<Bool>.Default {
    static var isRingLightEnabled: Self {
        Self[.appStorage("ringLight:isEnabled"), default: false]
    }
}

extension SharedKey where Self == AppStorageKey<Double>.Default {
    static var ringLightWidth: Self {
        Self[.appStorage("ringLight:width"), default: 160]
    }

    static var ringLightFeather: Self {
        Self[.appStorage("ringLight:feather"), default: 0.4]
    }

    static var ringLightIntensity: Self {
        Self[.appStorage("ringLight:intensity"), default: 0.85]
    }

    static var ringLightTemperature: Self {
        Self[.appStorage("ringLight:temperature"), default: 5200]
    }

    static var ringLightCornerRadius: Self {
        Self[.appStorage("ringLight:cornerRadius"), default: 0]
    }

    static var ringLightEdgeInset: Self {
        Self[.appStorage("ringLight:edgeInset"), default: 0]
    }
}
