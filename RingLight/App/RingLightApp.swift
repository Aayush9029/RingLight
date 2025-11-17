//
//  RingLightApp.swift
//  RingLight
//
//  Created by Aayush Pokharel on 2025-11-16.
//

import SwiftUI

@main
struct RingLightApp: App {
    @State private var controller = RingLightController()

    var body: some Scene {
        MenuBarExtra("Ring Light", systemImage: controller.isEnabled ? "rays" : "sparkles") {
            ContentView(controller: controller)
        }
        .menuBarExtraStyle(.window)
    }
}
