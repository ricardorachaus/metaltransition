//
//  DoomTransition.swift
//  DoomTransition
//
//  Created by Ricardo Rachaus on 15/11/22.
//

import Foundation
import MetalKit

private let device = MTLCreateSystemDefaultDevice()!

class DoomTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let duration: TimeInterval = 2
    let view = MetalView(device: device)
    let queue = DispatchQueue.main

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        duration
    }

    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {
        guard
            let from = transitionContext.viewController(forKey: .from),
            let to = transitionContext.viewController(forKey: .to)
        else { return }

        let container = transitionContext.containerView
        let frame = container.frame

        view.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)

        container.addSubview(to.view)
        container.addSubview(view)

        view.fromTexture = from.view.snapshot()
        view.toTexture = to.view.snapshot()

        queue.asyncAfter(deadline: .now() + duration) {
            self.view.removeFromSuperview()
            transitionContext.completeTransition(
                !transitionContext.transitionWasCancelled
            )
        }
    }

}

// From: https://stackoverflow.com/questions/61724043/render-uiview-contents-into-mtltexture
extension UIView {

    func snapshot() -> MTLTexture? {
        let width = Int(bounds.width)
        let height = Int(bounds.height)

        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        if let context, let data = context.data {
            layer.render(in: context)

            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm,
                width: width,
                height: height,
                mipmapped: false
            )
            descriptor.usage = [.shaderRead, .shaderWrite]

            if let texture = device.makeTexture(descriptor: descriptor) {
                texture.replace(
                    region: MTLRegionMake2D(0, 0, width, height),
                    mipmapLevel: 0,
                    withBytes: data,
                    bytesPerRow: context.bytesPerRow
                )
                return texture
            }
        }

        return nil
    }

}
