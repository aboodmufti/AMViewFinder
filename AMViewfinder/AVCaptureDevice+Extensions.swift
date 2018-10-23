//
//  AVCaptureDevice+Extensions.swift
//  AMViewfinder
//
//  Created by Abood Mufti on 2018-10-23.
//  Copyright © 2018 Abood Mufti. All rights reserved.
//

import AVFoundation


extension AVCaptureDevice {

    /// Calls the body after locking device.
    /// Once it's done it unlocks the device.
    func safeConfigure(_ body: () -> Void) {
        do{
            try lockForConfiguration()
            defer { unlockForConfiguration() }
            body()
        }catch {
            print("could not configure device")
        }
    }
}
