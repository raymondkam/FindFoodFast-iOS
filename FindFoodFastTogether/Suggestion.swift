//
//  Suggestion.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import UIKit

struct Suggestion {
    var name: String

    init(name: String) {
        self.name = name
    }
    
    init?(dictionary: [String: String]) {
        guard let name = dictionary["name"] else {
            print("invalid dictionary passed to Suggestion initializer")
            return nil
        }
        self.name = name
    }
    
    func asDictionary() -> [String: String] {
        var dict = [String: String]()
        dict.updateValue(name, forKey: "name")
        return dict
    }
}
