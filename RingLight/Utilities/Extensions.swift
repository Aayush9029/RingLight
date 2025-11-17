import AppKit

// MARK: - Utilities

func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
    max(minValue, min(value, maxValue))
}

// MARK: - NSColor Extension

extension NSColor {
    /// Approximate RGB value for a color temperature in Kelvin.
    convenience init(temperature: Double) {
        let capped = clamp(temperature, min: 1000, max: 40000)
        let temp = capped / 100

        let red: Double
        let green: Double
        let blue: Double

        if temp <= 66 {
            red = 255
            green = 99.4708025861 * log(temp) - 161.1195681661
            if temp <= 19 {
                blue = 0
            } else {
                blue = 138.5177312231 * log(temp - 10) - 305.0447927307
            }
        } else {
            red = 329.698727446 * pow(temp - 60, -0.1332047592)
            green = 288.1221695283 * pow(temp - 60, -0.0755148492)
            blue = 255
        }

        self.init(
            calibratedRed: clamp(red / 255, min: 0, max: 1),
            green: clamp(green / 255, min: 0, max: 1),
            blue: clamp(blue / 255, min: 0, max: 1),
            alpha: 1
        )
    }
}

// MARK: - NSScreen Extension

extension NSScreen {
    var menuBarInset: CGFloat {
        if #available(macOS 12.0, *) {
            return max(safeAreaInsets.top, NSStatusBar.system.thickness)
        } else {
            return NSStatusBar.system.thickness
        }
    }
}
