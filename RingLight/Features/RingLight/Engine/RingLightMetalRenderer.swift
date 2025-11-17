import AppKit
import MetalKit

// MARK: - Uniforms

struct RingLightUniforms {
    var resolution: SIMD2<Float> = .zero
    var ringWidth: Float = 0
    var feather: Float = 0
    var intensity: Float = 0
    var peakLuminance: Float = 1
    var color: SIMD3<Float> = .zero
    var safeTopInset: Float = 0
    var cornerRadius: Float = 0
}

// MARK: - HDR Metal Renderer

final class HDRRingLightRenderer: NSObject, MTKViewDelegate {
    var configuration: RingLightConfiguration = .default {
        didSet { uniformsNeedUpdate = true }
    }

    var topSafeInset: CGFloat = 0 {
        didSet { uniformsNeedUpdate = true }
    }

    private let mtkView: MTKView
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private var uniforms = RingLightUniforms()
    private var uniformsNeedUpdate = true
    private var drawableScale: CGFloat = 1 {
        didSet { updateDrawableSize() }
    }

    init?(hostView: NSView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue()
        else {
            return nil
        }

        self.commandQueue = commandQueue

        let mtkView = MTKView(frame: hostView.bounds, device: device)
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0)
        mtkView.layer?.isOpaque = false
        mtkView.layer?.wantsExtendedDynamicRangeContent = true
        mtkView.wantsExtendedDynamicRangeOpenGLSurface = true
        mtkView.wantsLayer = true
        mtkView.colorPixelFormat = .rgba16Float

        if #available(macOS 13.0, *) {
            mtkView.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
        } else {
            mtkView.colorspace = CGColorSpace(name: CGColorSpace.displayP3)
        }

        mtkView.autoresizingMask = [.width, .height]
        mtkView.translatesAutoresizingMaskIntoConstraints = true

        hostView.addSubview(mtkView, positioned: .above, relativeTo: nil)
        hostView.wantsLayer = true

        guard let library = device.makeDefaultLibrary() else {
            mtkView.removeFromSuperview()
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "ringLightVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "ringLightFragment")
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        guard let pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else {
            mtkView.removeFromSuperview()
            return nil
        }

        self.pipelineState = pipelineState
        self.mtkView = mtkView
        super.init()
        mtkView.delegate = self
        drawableSizeDidChange(to: hostView.bounds.size, scale: hostView.window?.backingScaleFactor ?? 1)
    }

    func drawableSizeDidChange(to size: CGSize, scale: CGFloat) {
        drawableScale = max(scale, 1)
        mtkView.drawableSize = CGSize(
            width: max(size.width * drawableScale, 1),
            height: max(size.height * drawableScale, 1)
        )
        uniformsNeedUpdate = true
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniformsNeedUpdate = true
    }

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        updateUniformsIfNeeded()

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            commandBuffer.commit()
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        var uniforms = self.uniforms
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<RingLightUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func updateDrawableSize() {
        mtkView.layer?.contentsScale = drawableScale
        mtkView.drawableSize = CGSize(
            width: max(mtkView.bounds.width * drawableScale, 1),
            height: max(mtkView.bounds.height * drawableScale, 1)
        )
    }

    private func updateUniformsIfNeeded() {
        guard uniformsNeedUpdate else { return }
        uniformsNeedUpdate = false

        let drawableSize = mtkView.drawableSize
        uniforms.resolution = SIMD2(
            Float(max(drawableSize.width, 1)),
            Float(max(drawableSize.height, 1))
        )

        let scale = Float(drawableScale)
        uniforms.ringWidth = Float(max(configuration.width, 20)) * scale
        uniforms.feather = Float(configuration.feather)
        uniforms.intensity = Float(configuration.intensity)
        uniforms.safeTopInset = min(Float(topSafeInset * CGFloat(scale)), uniforms.resolution.y)
        uniforms.cornerRadius = Float(max(configuration.cornerRadius, 0)) * scale

        let luminanceBoost = Float(1.0 + (configuration.intensity * 4))
        uniforms.peakLuminance = luminanceBoost

        uniforms.color = SIMD3(
            Float(configuration.glowColor.redComponent),
            Float(configuration.glowColor.greenComponent),
            Float(configuration.glowColor.blueComponent)
        )
    }
}
