//
//  ScreenClient.swift
//  RingLight
//
//  Dependency client for screen management
//

import AppKit
import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct ScreenClient: Sendable {
    var screens: @Sendable () -> [NSScreen] = { [] }
    var observeChanges: @Sendable (@escaping @Sendable () -> Void) async -> Void
}

extension ScreenClient: DependencyKey {
    static let liveValue = ScreenClient(
        screens: {
            NSScreen.screens
        },
        observeChanges: { onChange in
            await withCheckedContinuation { continuation in
                let observer = NotificationCenter.default.addObserver(
                    forName: NSApplication.didChangeScreenParametersNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    onChange()
                }
                continuation.resume()
            }
        }
    )

    static let testValue = ScreenClient(
        screens: {
            // Return a mock screen for testing
            []
        },
        observeChanges: { _ in
            // No-op for tests
        }
    )

    static let previewValue = ScreenClient(
        screens: {
            // Return mock screens for preview
            NSScreen.screens.isEmpty ? [] : [NSScreen.main!]
        },
        observeChanges: { _ in
            // No-op for previews
        }
    )
}

extension DependencyValues {
    var screenClient: ScreenClient {
        get { self[ScreenClient.self] }
        set { self[ScreenClient.self] = newValue }
    }
}
