//
//  VerticallyCenteredTextView.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-02.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class VerticallyCenteredTextView: UITextView {
    override var contentSize: CGSize {
        didSet {
            var topCorrection = (bounds.size.height - contentSize.height * zoomScale) / 2.0
            topCorrection = max(0, topCorrection)
            contentInset = UIEdgeInsets(top: topCorrection, left: 0, bottom: 0, right: 0)
        }
    }
}
