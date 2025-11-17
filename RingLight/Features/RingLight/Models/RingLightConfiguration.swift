import AppKit
import SwiftUI

// MARK: - Configuration

struct RingLightConfiguration: Equatable {
    var width: CGFloat
    var feather: CGFloat
    var intensity: CGFloat
    var temperature: Double
    var cornerRadius: CGFloat
    var edgeInset: CGFloat

    static let `default` = RingLightConfiguration(
        width: 160,
        feather: 0.4,
        intensity: 0.85,
        temperature: 5200,
        cornerRadius: 0,
        edgeInset: 0
    )

    var glowColor: NSColor {
        NSColor(temperature: temperature)
    }

    var resolvedColor: NSColor {
        glowColor.withAlphaComponent(max(0, min(1, intensity)))
    }

    var swiftUIColor: Color {
        Color(nsColor: resolvedColor)
    }
}

// MARK: - Screen Identification

struct ScreenIdentifier: Hashable {
    let rawValue: UInt32

    init?(screen: NSScreen) {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        rawValue = number.uint32Value
    }
}
