//
//  SuggestionCollectionViewCell.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class SuggestionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    var title:String? {
        get {
            return self.titleLabel.text
        }
        set(newTitle) {
            self.titleLabel.text = newTitle
        }
    }
}
