//
//  ImageCollectionViewCell.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-27.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var imageUrl: URL {
        get {
            return self.imageUrl
        }
        set {
            do {
                try imageView.image = UIImage(data: Data(contentsOf: newValue))
            } catch {
                print("error fetching image")
            }
        }
    }
}
