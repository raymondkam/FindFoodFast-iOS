//
//  User.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-30.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation

struct User {
    var name: String
    var uuidString: String
    
    init(name: String, uuidString: String) {
        self.name = name
        self.uuidString = uuidString
    }
}
