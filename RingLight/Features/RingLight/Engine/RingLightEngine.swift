import AppKit
import Dependencies

// MARK: - Window Management Engine

@MainActor
final class RingLightEngine {
    private var configuration = RingLightConfiguration.default
    private var isEnabled = false
    private var windows: [ScreenIdentifier: RingLightWindow] = [:]
    private var screenObserver: NSObjectProtocol?
    private let screenClient: ScreenClient

    init(screenClient: ScreenClient) {
        self.screenClient = screenClient
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildForScreenChange()
        }
    }

    deinit {
        if let token = screenObserver {
            NotificationCenter.default.removeObserver(token)
        }
        MainActor.assumeIsolated {
            tearDownWindows()
        }
    }

    func update(isEnabled: Bool, configuration: RingLightConfiguration) {
        self.configuration = configuration
        self.isEnabled = isEnabled

        if isEnabled {
            realizeWindowsIfNeeded()
            applyConfigurationToActiveWindows()
        } else {
            tearDownWindows()
        }
    }

    private func rebuildForScreenChange() {
        guard isEnabled else {
            tearDownWindows()
            return
        }

        realizeWindowsIfNeeded()
        applyConfigurationToActiveWindows()
    }

    private func realizeWindowsIfNeeded() {
        let currentScreens = screenClient.screens().compactMap { screen -> (ScreenIdentifier, NSScreen)? in
            guard let identifier = ScreenIdentifier(screen: screen) else { return nil }
            return (identifier, screen)
        }

        var seenIdentifiers = Set<ScreenIdentifier>()

        for (identifier, screen) in currentScreens {
            seenIdentifiers.insert(identifier)

            if let window = windows[identifier] {
                window.update(for: screen)
                continue
            }

            let window = RingLightWindow(screen: screen)
            windows[identifier] = window
        }

        let staleIdentifiers = Set(windows.keys).subtracting(seenIdentifiers)
        for identifier in staleIdentifiers {
            windows[identifier]?.close()
            windows.removeValue(forKey: identifier)
        }
    }

    private func applyConfigurationToActiveWindows() {
        for window in windows.values {
            window.apply(configuration: configuration)
        }
    }

    private func tearDownWindows() {
        for window in windows.values {
            window.orderOut(nil)
            window.close()
        }

        windows.removeAll(keepingCapacity: false)
    }
}
