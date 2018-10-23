//
//  UIImage+Extensions.swift
//  AMViewfinder
//
//  Created by Abood Mufti on 2018-10-23.
//  Copyright © 2018 Abood Mufti. All rights reserved.
//

import UIKit
import AVFoundation

extension UIImage {

    /// crops the calling image to the bounds of the given preview layer.
    func cropped(toBoundsOf previewLayer: AVCaptureVideoPreviewLayer) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        let outputRect = previewLayer.metadataOutputRectConverted(fromLayerRect: previewLayer.bounds)

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let cropRect = CGRect(
            x: outputRect.origin.x * width,
            y: outputRect.origin.y * height,
            width: outputRect.size.width * width,
            height: outputRect.size.height * height)

        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return nil}

        let croppedImage = UIImage(
            cgImage: croppedCgImage,
            scale: self.scale,
            orientation: self.imageOrientation
        )

        return croppedImage
    }
}
