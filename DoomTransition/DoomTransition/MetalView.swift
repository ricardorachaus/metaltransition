//
//  MetalView.swift
//  DoomTransition
//
//  Created by Ricardo Rachaus on 16/11/22.
//
import MetalKit

final class MetalView: MTKView {

    let positions = [
        SIMD3<Float>(-1,  1, 0), // Top Left
        SIMD3<Float>(-1, -1, 0), // Bottom Left
        SIMD3<Float>( 1, -1, 0), // Bottom Right

        SIMD3<Float>( 1,  1, 0), // Top Right
        SIMD3<Float>(-1,  1, 0), // Top Left
        SIMD3<Float>( 1, -1, 0), // Bottom Right
    ]

    let textureCoordinates = [
        SIMD2<Float>(0, 0), // Top Left
        SIMD2<Float>(0, 1), // Bottom Left
        SIMD2<Float>(1, 1), // Bottom Right

        SIMD2<Float>(1, 0), // Top Right
        SIMD2<Float>(0, 0), // Top Left
        SIMD2<Float>(1, 1), // Bottom Right
    ]

    var vertexBuffer: MTLBuffer!
    var renderPipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var sampler: MTLSamplerState!

    var fromTexture: MTLTexture?
    var toTexture: MTLTexture?
    var deltaTime: Float = 0

    override init(frame: CGRect = .zero, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        vertexBuffer = device!.makeBuffer(
            bytes: positions,
            length: MemoryLayout<SIMD3<Float>>.stride * positions.count
        )
        commandQueue = device!.makeCommandQueue()

        createRenderPipelineState()
        sampler = device!.makeSamplerState(descriptor: MTLSamplerDescriptor())
    }

    func createRenderPipelineState() {
        let library = device!.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "main_vertex")!
        let fragmentFunction = library.makeFunction(name: "doom_melt")!

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0

        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.size

        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        + MemoryLayout<SIMD2<Float>>.stride

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor

        renderPipelineState = try! device!.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }

    override func draw(_ rect: CGRect) {
        guard
            let drawable = currentDrawable,
            let renderPassDescriptor = currentRenderPassDescriptor
        else { return }

        deltaTime += 1 / Float(preferredFramesPerSecond)

        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        commandEncoder?.setRenderPipelineState(renderPipelineState)
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        commandEncoder?.setVertexBytes(
            textureCoordinates,
            length: MemoryLayout<SIMD2<Float>>.stride * textureCoordinates.count,
            index: 1
        )

        if let fromTexture, let toTexture {
            commandEncoder?.setFragmentTexture(fromTexture, index: 0)
            commandEncoder?.setFragmentTexture(toTexture, index: 1)
            commandEncoder?.setFragmentSamplerState(sampler, index: 0)
            commandEncoder?.setFragmentBytes(
                &deltaTime,
                length: MemoryLayout<Float>.stride,
                index: 0
            )
        }

        commandEncoder?.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: positions.count
        )
        commandEncoder?.endEncoding()

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

}
