//
//  BluetoothRefreshView.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-09-04.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class BluetoothRefreshView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var topShadowView: UIView!
    @IBOutlet weak var bottomShadowView: UIView!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var gradientView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BluetoothRefreshView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
    }
    
}
