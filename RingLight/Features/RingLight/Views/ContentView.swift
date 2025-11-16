//
//  ContentView.swift
//  RingLight
//
//  Created by Aayush Pokharel on 2025-11-16.
//

import Dependencies
import SwiftUI

struct ContentView: View {
    @Bindable var controller: RingLightController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Divider()

            parameterSection(title: "Ring width", valueLabel: "\(Int(controller.width))") {
                Slider(value: $controller.width, in: 40...400, step: 5)
            }

            parameterSection(title: "Corner radius", valueLabel: "\(Int(controller.cornerRadius))") {
                Slider(value: $controller.cornerRadius, in: 0...500, step: 5)
            }

            parameterSection(title: "Brightness", valueLabel: "\(Int(controller.intensity * 100))%") {
                Slider(value: $controller.intensity, in: 0.1...1)
            }

            parameterSection(title: "Softness", valueLabel: String(format: "%.0f%%", controller.feather * 100)) {
                Slider(value: $controller.feather, in: 0...0.9)
            }

            parameterSection(title: "Color temperature", valueLabel: "\(Int(controller.temperature))K") {
                Slider(value: $controller.temperature, in: 2800...7000, step: 50)
            }

            TemperaturePresetRow(controller: controller)
        }
        .padding(16)
        .frame(width: 360)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle(isOn: $controller.isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ring Light")
                            .font(.headline)
                        Text(controller.isEnabled ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                Spacer()

                Circle()
                    .fill(controller.previewColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: controller.previewColor.opacity(0.6), radius: 8, x: 0, y: 0)
            }

            Text("Professional lighting for video calls and recordings.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func parameterSection<Content: View>(title: String, valueLabel: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(valueLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            content()
        }
    }
}

private struct TemperaturePresetRow: View {
    var controller: RingLightController

    var body: some View {
        HStack {
            TemperaturePresetButton(title: "Warm", kelvin: 3400, controller: controller)
            TemperaturePresetButton(title: "Neutral", kelvin: 5200, controller: controller)
            TemperaturePresetButton(title: "Cool", kelvin: 6500, controller: controller)
        }
    }
}

private struct TemperaturePresetButton: View {
    let title: String
    let kelvin: Double
    var controller: RingLightController

    var isSelected: Bool {
        abs(controller.temperature - kelvin) < 50
    }

    var body: some View {
        Button {
            controller.applyPresetTemperature(kelvin)
        } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(Int(kelvin))K")
                    .font(.caption2)
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderedProminent)
        .tint(isSelected ? controller.previewColor : .secondary)
    }
}

#Preview {
    let _ = prepareDependencies {
        $0.screenClient = .previewValue
    }
    ContentView(controller: RingLightController())
}
