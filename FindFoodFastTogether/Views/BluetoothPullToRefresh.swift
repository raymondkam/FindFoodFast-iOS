//
//  BluetoothPullToRefresh.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-09-04.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import PullToRefresh

class BluetoothPullToRefresh: PullToRefresh {
    
    convenience init(height: CGFloat, position: Position) {
        let refreshView = BluetoothRefreshView()
        refreshView.frame.size.height = height
        let animator = BluetoothRefreshViewAnimator(refreshView: refreshView)
        self.init(refreshView: refreshView, animator: animator, height: height, position: position)
        refreshView.gradientView.frame.size.height = height
        refreshView.gradientView.addGradientLayer(colors: FindFoodFastColor.seaweedGradient.reversed(), at: nil)
        refreshView.topShadowView.addShadow(with: CGSize(width: 0, height: 0.5), opacity: nil, masksToBounds: true)
        refreshView.bottomShadowView.addShadow(with: CGSize(width: 0, height: -0.5), opacity: nil, masksToBounds: true)
    }
}
