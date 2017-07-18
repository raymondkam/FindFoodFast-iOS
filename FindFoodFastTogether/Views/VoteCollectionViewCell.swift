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
    @IBOutlet private weak var noImageLabel: UILabel!
    @IBOutlet private weak var titlelabel: UILabel!
    @IBOutlet weak var cosmoView: CosmosView!
    
    var title: String? {
        get {
            return titlelabel.text
        }
        set(newTitle) {
            titlelabel.text = newTitle
        }
    }
    
    var noImageTitle: String? {
        get {
            return noImageLabel.text
        }
        set(newNoImageTitle) {
            noImageLabel.text = newNoImageTitle
        }
    }
}
