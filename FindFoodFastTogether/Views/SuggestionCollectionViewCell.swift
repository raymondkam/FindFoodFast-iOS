//
//  SuggestionCollectionViewCell.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import Cosmos

class SuggestionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ratingCosmosView: CosmosView!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var image: UIImage? {
        get {
            return imageView.image
        }
        set(newImage) {
            imageView.image = newImage
        }
    }
    
    var title: String? {
        get {
            return titleLabel.text
        }
        set(newTitle) {
            titleLabel.text = newTitle
        }
    }
    
    var rating: Double? {
        get {
            return ratingCosmosView.rating
        }
        set(newRating) {
            if let newRating = newRating {
                ratingCosmosView.rating = newRating
                ratingLabel.text = String(format: "%.1f", newRating)
                ratingView.isHidden = false
            } else {
                ratingView.isHidden = true
            }
        }
    }
    
    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set (newSubtitle) {
            subtitleLabel.text = newSubtitle
        }
    }
}
