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

    init(name: String) {
        self.name = name
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
            return nil
        }
        self.name = name
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
    }
}