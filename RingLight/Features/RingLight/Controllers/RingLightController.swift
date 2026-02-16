import Combine
import Dependencies
import Sharing
import SwiftUI

// MARK: - Display Info

struct DisplayInfo: Identifiable, Hashable {
    let id: UInt32
    let name: String
}

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

    @ObservationIgnored
    @Shared(.ringLightSelectedDisplayIDs) var selectedDisplayIDs: String = "" {
        didSet { pushUpdate() }
    }

    var selectedDisplayIDSet: Set<UInt32> {
        let ids = selectedDisplayIDs.split(separator: ",").compactMap { UInt32($0) }
        return Set(ids)
    }

    func toggleDisplay(_ id: UInt32) {
        var idSet = selectedDisplayIDSet
        if idSet.contains(id) {
            idSet.remove(id)
        } else {
            idSet.insert(id)
        }
        $selectedDisplayIDs.withLock {
            $0 = idSet.sorted().map(String.init).joined(separator: ",")
        }
        pushUpdate()
    }

    func isDisplaySelected(_ id: UInt32) -> Bool {
        let idSet = selectedDisplayIDSet
        return idSet.isEmpty || idSet.contains(id)
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

    func availableDisplays() -> [DisplayInfo] {
        @Dependency(\.screenClient) var screenClient
        var displays: [DisplayInfo] = []

        let screens = screenClient.screens()
        for (index, screen) in screens.enumerated() {
            if let identifier = ScreenIdentifier(screen: screen) {
                let name = screen.localizedName.isEmpty ? "Display \(index + 1)" : screen.localizedName
                displays.append(DisplayInfo(id: identifier.rawValue, name: name))
            }
        }

        return displays
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
        engine.update(isEnabled: isEnabled, configuration: configuration, selectedDisplayIDs: selectedDisplayIDSet)
    }
}
