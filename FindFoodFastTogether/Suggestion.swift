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
    var address: String?
    var rating = 0

    init(name: String, address: String?, rating: Int?) {
        self.name = name
        self.address = address
        if let rating = rating {
            self.rating = rating
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
            print("suggestion init: could not decode name")
            return nil
        }
        if let address = aDecoder.decodeObject(forKey: "address") as? String {
            self.address = address
        }
        let rating = aDecoder.decodeInteger(forKey: "rating")
        self.name = name
        self.rating = rating
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(rating, forKey: "rating")
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let suggestion = object as? Suggestion else {
            return false
        }
        return suggestion.name == self.name && suggestion.address == self.address
    }
    
    override var hashValue: Int {
        return name.hashValue
    }
    
    override var description: String {
        return "Suggestion(name: \(name), rating: \(rating))"
    }
}
