//
//  SuggestionSearchResultCollectionViewCell.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-26.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

enum DistanceUnit {
    case kilometer
    case meter
}

class SuggestionSearchResultCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    
    var title: String? {
        get {
            return titleLabel.text
        }
        set(newTitle) {
            titleLabel.text = newTitle
        }
    }
    
    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set(newSubtitle) {
            guard let newSubtitle = newSubtitle else {
                subtitleLabel.isHidden = true
                return
            }
            subtitleLabel.isHidden = false
            subtitleLabel.text = newSubtitle
        }
    }
    
    var distance: (magnitude: String, unit: DistanceUnit)? {
        get {
            return self.distance
        }
        set {
            guard let newValue = newValue else {
                distanceLabel.isHidden = true
                return
            }
            distanceLabel.isHidden = false
            switch newValue.unit {
            case .kilometer:
                distanceLabel.text = "\(newValue.magnitude) km"
            case .meter:
                distanceLabel.text = "\(newValue.magnitude) m"
            }
        }
    }
    
}
