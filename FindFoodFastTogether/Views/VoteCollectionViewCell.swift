//
//  VoteCollectionViewCell.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-18.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import Cosmos

class VoteCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var titlelabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet weak var cosmoView: CosmosView!
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set(newImage) {
            UIView.transition(with: imageView,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                                self.imageView.image = newImage
            },
                              completion: nil)
        }
    }
    
    var title: String? {
        get {
            return titlelabel.text
        }
        set(newTitle) {
            titlelabel.text = newTitle
        }
    }
    
    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set(newSubtitle) {
            subtitleLabel.text = newSubtitle
        }
    }
    
    var distance: String? {
        get {
            return distanceLabel.text
        }
        set {
            if let newDistance = newValue {
                distanceLabel.text = newDistance
                distanceLabel.isHidden = false
            } else {
                distanceLabel.isHidden = true
            }
        }
    }
}
