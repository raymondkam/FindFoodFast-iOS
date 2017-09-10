//
//  BluetoothRefreshView.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-09-04.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class BluetoothRefreshView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var topShadowView: UIView!
    @IBOutlet weak var bottomShadowView: UIView!

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
