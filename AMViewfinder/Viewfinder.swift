//
//  Viewfinder.swift
//  AMViewfinder
//
//  Created by Abood Mufti on 2018-10-15.
//  Copyright © 2018 Abood Mufti. All rights reserved.
//

import UIKit
import AVFoundation
import AMConstraints


class Viewfinder: UIView {

    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        return session
    }()

    private lazy var photoOutput: AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput()
        output.isHighResolutionCaptureEnabled = true
        return output
    }()

    private lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait

        layer.addSublayer(previewLayer)

        return previewLayer
    }()

    private lazy var focusSquare: UIView = {
        let square = UIView()
        square.isHidden = true
        square.layer.borderColor = UIColor(red: 1, green: 0.8, blue: 0, alpha: 1).cgColor
        square.layer.borderWidth = 2
        addSubview(square)

        focusSquareWidthConstraint = square.constrain(dimensions: .width, to: self, multiplier: 2).width
        square.constrain(dimension: .height, to: .width, of: square)

        return square
    }()

    private var cameraPosition: AVCaptureDevice.Position = .back
    private var camera: AVCaptureDevice?
    private var input: AVCaptureDeviceInput?
    private var focusSquareWidthConstraint: NSLayoutConstraint?
    private var focusSquareAxes: Axes?
    private var imageCaptureCallback: ((UIImage?) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = self.bounds
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        clipsToBounds = true
        backgroundColor = .gray

        let tap = UITapGestureRecognizer(target: self, action: #selector(videoPreviewTapped(_:)))
        addGestureRecognizer(tap)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(videoPreviewPinched(_:)))
        addGestureRecognizer(pinch)

        configureSession()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cameraFocusDidChange),
                                               name: .AVCaptureDeviceSubjectAreaDidChange,
                                               object: nil)
    }

    private func makeDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        guard let device =  AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
                                                             mediaType: .video,
                                                             position: position).devices.first  else { return nil }

        device.safeConfigure { device.isSubjectAreaChangeMonitoringEnabled = true }
        return device
    }

    @objc private func cameraFocusDidChange() {
        guard let device = camera else { return }
        device.safeConfigure {
            if !focusSquare.isHidden {
                // center focus square
                focusSquareAxes?.centerX?.isActive = false
                focusSquareAxes?.centerY?.isActive = false
                focusSquareAxes = focusSquare.constrain(axes: .all, to: self)

                // make the square a little bigger
                updateFocusSquare(multiplier: 0.3)

                Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
                    self.focusSquare.animate(animations: {
                        self.focusSquare.isHidden = true
                    })
                })
            }

            if device.isFocusPointOfInterestSupported {
                device.focusMode = .continuousAutoFocus
            }

            if device.isExposurePointOfInterestSupported {
                device.exposureMode = .continuousAutoExposure
            }
        }
    }

    private func updateFocusSquare(multiplier: CGFloat) {
        focusSquareWidthConstraint?.isActive = false
        focusSquareWidthConstraint = focusSquare.constrain(dimensions: .width, to: self, multiplier: multiplier).width
    }

    @objc private func videoPreviewPinched(_ pinch: UIPinchGestureRecognizer) {
        guard let device = camera else { return }

        if pinch.state == .began {
            // This makes the user continue zooming where they left off,
            // instead of snapping back to "no-zoom" every time they pinch.
            pinch.scale = device.videoZoomFactor
            return
        }

        device.safeConfigure {
            device.videoZoomFactor = max(1.0, min(pinch.scale, device.activeFormat.videoMaxZoomFactor))
        }
    }

    /// Adjusts focus and exposure points based on the users' touch on the preview view.
    @objc private func videoPreviewTapped(_ tap: UITapGestureRecognizer){
        guard let device = camera else { return }

        let location = tap.location(in: self)
        let focusPoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: location)

        device.safeConfigure {
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }

            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .autoExpose
            }

            // update focus square position
            updateFocusSquare(multiplier: 0.2)

            focusSquareAxes?.centerX?.isActive = false
            focusSquareAxes?.centerY?.isActive = false
            focusSquareAxes = focusSquare.constrainCenter(to: location, in: self)

            focusSquare.animate(animations: {
                self.focusSquare.isHidden = false
            })
        }
    }

    /// Creates and returns a new `AVCapturePhotoSettings` with JPEG codec type.
    /// It also sets the flash mode based on the one passed to the function.
    private func createOutputSettings(flashMode: AVCaptureDevice.FlashMode) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        settings.flashMode = flashMode
        return settings
    }

    /// Captures a photo and calls the callback with a cropped
    /// image based on the Viewfinder's bounds.
    public func capturePhoto(flashMode: AVCaptureDevice.FlashMode, callback: (UIImage?) -> Void) {
        let settings = createOutputSettings(flashMode: flashMode)
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// Switch between front and back camera
    public func switchCamera() {
        cameraPosition = cameraPosition == .back ? .front : .back
        configureSession()
    }

    /// Configures the input and output and starts the session
    public func configureSession() {
        if let input = input {
            session.removeInput(input)
            self.input = nil
        }

        camera = makeDevice(for: cameraPosition)

        guard let device = camera else { return }

        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch let error {
            print("AVCaptureDeviceInput init error: \(error)")
            return
        }

        guard let input = input, session.canAddInput(input) else { return }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else { return }
        session.addOutput(photoOutput)

        session.startRunning()
    }

}

extension Viewfinder: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // fake capture: display white screen for a split second
        let whiteView = UIView()
        whiteView.backgroundColor = .white
        addSubview(whiteView)
        whiteView.constrain(sides: .all, to: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            whiteView.removeFromSuperview()
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
            let data = photo.fileDataRepresentation(),
            let rawImage = UIImage(data: data),
            let cgImage = rawImage.cgImage
            else { return }

        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        let croppedImage = image.cropped(toBoundsOf: videoPreviewLayer)

        imageCaptureCallback?(croppedImage)
        imageCaptureCallback = nil
    }
}

