[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License][license-image]][license-url]

# AMViewfinder
An iOS library that takes care of displaying a viewfinder

## Installation

### Carthage
1. Add the following to your Cartfile

        github "aboodmufti/AMViewfinder"
        
2. Run `carthage update`
3. Add the framework to your project, as defined [here](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos)

## Usage:

```Swift
lazy var cameraViewfinder: Viewfinder = {
    let cameraView = Viewfinder()

    view.addSubview(cameraView)
    cameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    cameraView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    cameraView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor).isActive = true

    return cameraView
}()

lazy var previewImageView: UIImageView = {
    let imageview = UIImageView()
    imageview.isHidden = true

    view.addSubview(imageview)
    imageview.topAnchor.constraint(equalTo: cameraView.topAnchor).isActive = true
    imageview.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor).isActive = true
    imageview.leftAnchor.constraint(equalTo: cameraView.leftAnchor).isActive = true
    imageview.rightAnchor.constraint(equalTo: cameraView.rightAnchor).isActive = true
    
    return imageview
}()

...

@objc func switchButtonWasTapped(){ 
    cameraViewfinder.switchCamera() 
}

@objc func captureButtonWasTapped() {
    cameraViewfinder.capturePhoto(flashMode: .off) { croppedImage in
        previewImageView.image = croppedImage
        previewImageView.isHidden = false
    }
}

```

## Contribute
Contributions to AMConstraints are more than welcome, check the `LICENSE` file for more info.


[license-image]: https://img.shields.io/hexpm/l/plug.svg
[license-url]: LICENSE
