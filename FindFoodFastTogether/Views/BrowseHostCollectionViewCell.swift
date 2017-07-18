//
//  BrowseHostCollectionViewCell.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-13.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class BrowseHostCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    var title:String? {
        get {
            return titleLabel.text
        }
        set(newTitle) {
            titleLabel.text = newTitle
        }
    }
    
    var thumbnail:UIImage? {
        get {
            return thumbnailImageView.image
        }
        set(newThumbnail) {
            thumbnailImageView.image = newThumbnail
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
