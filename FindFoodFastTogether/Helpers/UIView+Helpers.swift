//
//  UIView+Helpers.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-23.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    func addShadow(with offset: CGSize, opacity: Float?, masksToBounds: Bool?) {
        let shadowPath = UIBezierPath(rect: bounds)
        layer.masksToBounds = masksToBounds ?? false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity ?? Float(0.3)
        layer.shadowPath = shadowPath.cgPath
    }
}
