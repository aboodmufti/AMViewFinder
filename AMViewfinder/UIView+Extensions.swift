//
//  UIView+Extensions.swift
//  AMViewfinder
//
//  Created by Abood Mufti on 2018-10-23.
//  Copyright © 2018 Abood Mufti. All rights reserved.
//

import UIKit


extension UIView {

    /// Animate any property of the calling view.
    ///

    /// Example:
    /// ```
    /// view.animate { view.isHidden = true }
    /// ```
    /// - Parameters:
    ///     - duration: Duration of the animation. Default: `0.3`
    ///     - options: Animation options. Default: `.transitionCrossDissolve`
    ///     - animations: Block where _only_ the properties of the calling view should be set.
    func animate(duration: TimeInterval = 0.3, options: UIView.AnimationOptions = .transitionCrossDissolve, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.transition(with: self,
                          duration: duration,
                          options: options,
                          animations: animations,
                          completion: completion)
    }

}
