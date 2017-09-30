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
    
    func addGradientLayer(colors: [CGColor], at index:UInt32?) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.colors = colors
        if let index = index {
            layer.insertSublayer(gradientLayer, at: index)
        } else {
            layer.addSublayer(gradientLayer)
        }
        return gradientLayer
    }
}
