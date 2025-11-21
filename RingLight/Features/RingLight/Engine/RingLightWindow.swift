import AppKit
import QuartzCore

// MARK: - Window

final class RingLightWindow: NSPanel {
    private let glowView = GlowGradientView(frame: .zero)

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        hasShadow = false
        backgroundColor = .clear
        isReleasedWhenClosed = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        animationBehavior = .none
        hidesOnDeactivate = false
        isExcludedFromWindowsMenu = true
        preventsApplicationTerminationWhenModal = true
        isMovable = false
        isFloatingPanel = true
        contentView = glowView
        glowView.autoresizingMask = [.width, .height]
        update(for: screen)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func update(for screen: NSScreen) {
        setFrame(screen.frame, display: true)
        glowView.frame = NSRect(origin: .zero, size: screen.frame.size)
        glowView.topSafeInset = screen.menuBarInset
    }

    func apply(configuration: RingLightConfiguration) {
        glowView.configuration = configuration
        orderFrontRegardless()
    }
}

// MARK: - Glow Gradient View

final class GlowGradientView: NSView {
    var configuration: RingLightConfiguration = .default {
        didSet { propagateConfigurationChange() }
    }

    var topSafeInset: CGFloat = 0 {
        didSet { propagateConfigurationChange() }
    }

    private let fallbackContainer = CALayer()
    private let topGradient = CAGradientLayer()
    private let bottomGradient = CAGradientLayer()
    private let leftGradient = CAGradientLayer()
    private let rightGradient = CAGradientLayer()
    private var fallbackConfigured = false

    private var metalRenderer: HDRRingLightRenderer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor.clear.cgColor

        if let renderer = HDRRingLightRenderer(hostView: self) {
            metalRenderer = renderer
        } else {
            setupFallbackGradientsIfNeeded()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        syncScaleAndDrawableSize()
        propagateConfigurationChange()
    }

    override func layout() {
        super.layout()
        syncScaleAndDrawableSize()
        propagateConfigurationChange()
    }

    private func syncScaleAndDrawableSize() {
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
        metalRenderer?.drawableSizeDidChange(to: bounds.size, scale: scale)
    }

    private func propagateConfigurationChange() {
        if let renderer = metalRenderer {
            renderer.configuration = configuration
            renderer.topSafeInset = topSafeInset
        } else {
            updateFallbackGradients()
        }
    }

    private func setupFallbackGradientsIfNeeded() {
        guard !fallbackConfigured, let backingLayer = layer else { return }
        fallbackConfigured = true
        fallbackContainer.frame = bounds
        fallbackContainer.backgroundColor = NSColor.clear.cgColor
        fallbackContainer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        backingLayer.addSublayer(fallbackContainer)

        for gradient in [topGradient, bottomGradient, leftGradient, rightGradient] {
            gradient.type = .axial
            gradient.isOpaque = false
            gradient.locations = [0, 1]
            fallbackContainer.addSublayer(gradient)
        }
    }

    private func updateFallbackGradients() {
        setupFallbackGradientsIfNeeded()
        guard fallbackConfigured else { return }

        fallbackContainer.frame = bounds

        let targetWidth = min(max(configuration.width, 10), min(bounds.width, bounds.height) / 2)
        let color = configuration.resolvedColor
        let transparent = color.withAlphaComponent(0)
        let softness = Double(clamp(CGFloat(configuration.feather), min: 0, max: 0.95))
        let hardStop = NSNumber(value: Float(max(0.001, 1 - softness)))
        let colors: [CGColor] = [color.cgColor, color.cgColor, transparent.cgColor]
        let locations: [NSNumber] = [0, hardStop, 1]

        for gradient in [topGradient, bottomGradient, leftGradient, rightGradient] {
            gradient.colors = colors
            gradient.locations = locations
            gradient.isHidden = configuration.intensity <= 0.01
        }

        // Account for ring width to prevent clipping into menu bar
        let effectiveTopInset = clamp(topSafeInset + targetWidth, min: 0, max: bounds.height)
        let availableHeight = max(bounds.height - effectiveTopInset, 0)
        
        // Position top gradient: extends from topGradientY upward by topGradientHeight
        // Clamped to ensure it stays within the available drawing area
        let topGradientY = max(0, availableHeight - targetWidth)
        let topGradientHeight = min(targetWidth, availableHeight)

        topGradient.startPoint = CGPoint(x: 0.5, y: 1)
        topGradient.endPoint = CGPoint(x: 0.5, y: 0)
        bottomGradient.startPoint = CGPoint(x: 0.5, y: 0)
        bottomGradient.endPoint = CGPoint(x: 0.5, y: 1)
        leftGradient.startPoint = CGPoint(x: 0, y: 0.5)
        leftGradient.endPoint = CGPoint(x: 1, y: 0.5)
        rightGradient.startPoint = CGPoint(x: 1, y: 0.5)
        rightGradient.endPoint = CGPoint(x: 0, y: 0.5)

        topGradient.frame = CGRect(
            x: 0,
            y: topGradientY,
            width: bounds.width,
            height: topGradientHeight
        )
        bottomGradient.frame = CGRect(x: 0, y: 0, width: bounds.width, height: targetWidth)
        leftGradient.frame = CGRect(x: 0, y: 0, width: targetWidth, height: availableHeight)
        rightGradient.frame = CGRect(
            x: bounds.width - targetWidth,
            y: 0,
            width: targetWidth,
            height: availableHeight
        )
    }
}
