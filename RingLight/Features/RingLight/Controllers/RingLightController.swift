import Combine
import Dependencies
import Sharing
import SwiftUI

// MARK: - Ring Light Controller

@MainActor
@Observable
final class RingLightController {
    @ObservationIgnored
    @Shared(.isRingLightEnabled) var isEnabled = false {
        didSet { pushUpdate() }
    }

    @ObservationIgnored
    @Shared(.ringLightWidth) var width: Double = 160 {
        didSet { pushUpdate() }
    }

    @ObservationIgnored
    @Shared(.ringLightFeather) var feather: Double = 0.4 {
        didSet { pushUpdate() }
    }

    @ObservationIgnored
    @Shared(.ringLightTemperature) var temperature: Double = 5200 {
        didSet { pushUpdate() }
    }

    @ObservationIgnored
    @Shared(.ringLightIntensity) var intensity: Double = 0.85 {
        didSet { pushUpdate() }
    }

    @ObservationIgnored
    @Shared(.ringLightCornerRadius) var cornerRadius: Double = 0 {
        didSet { pushUpdate() }
    }

    @ObservationIgnored
    @Shared(.ringLightEdgeInset) var edgeInset: Double = 0 {
        didSet { pushUpdate() }
    }

    var previewColor: Color {
        configuration.swiftUIColor
    }

    @ObservationIgnored
    private var engine: RingLightEngine

    init() {
        @Dependency(\.screenClient) var screenClient
        engine = RingLightEngine(screenClient: screenClient)
    }

    func applyPresetTemperature(_ kelvin: Double) {
        $temperature.withLock { $0 = kelvin }
    }

    private var configuration: RingLightConfiguration {
        RingLightConfiguration(
            width: CGFloat(clamp(width, min: 20, max: 400)),
            feather: CGFloat(clamp(feather, min: 0, max: 0.95)),
            intensity: CGFloat(clamp(intensity, min: 0.05, max: 1)),
            temperature: clamp(temperature, min: 2500, max: 7500),
            cornerRadius: CGFloat(clamp(cornerRadius, min: 0, max: 500)),
            edgeInset: CGFloat(clamp(edgeInset, min: 0, max: 200))
        )
    }

    private func pushUpdate() {
        engine.update(isEnabled: isEnabled, configuration: configuration)
    }
}
