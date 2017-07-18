//
//  Suggestion.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import UIKit

class Suggestion: NSObject, NSCoding {
    var name: String
    var rating: Int

    init(name: String, rating: Int) {
        self.name = name
        self.rating = rating
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
            print("suggestion init: could not decode name")
            return nil
        }
        let rating = aDecoder.decodeInteger(forKey: "rating")
        self.name = name
        self.rating = rating
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(rating, forKey: "rating")
    }
}
