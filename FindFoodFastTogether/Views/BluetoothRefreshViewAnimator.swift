//
//  BluetoothRefreshViewAnimator.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-09-04.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import PullToRefresh

class BluetoothRefreshViewAnimator: RefreshViewAnimator {
    
    private let refreshView: BluetoothRefreshView
    
    init(refreshView: BluetoothRefreshView) {
        self.refreshView = refreshView
    }
    
    func animate(_ state: State) {
        switch state {
        case .initial:
            // do inital layout for elements
            refreshView.backgroundColor = UIColor.gray
        case .releasing(let progress):
            // animate elements according to progress
            break
        case .loading: // start loading animations
            refreshView.activityIndicator.startAnimating()
        case .finished: // show some finished state if needed
            refreshView.activityIndicator.stopAnimating()
        }
    }
}
