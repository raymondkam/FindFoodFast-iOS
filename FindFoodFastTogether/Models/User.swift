//
//  User.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-30.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation

class User: NSObject {
    var name: String
    var uuidString: String
    
    init(name: String, uuidString: String) {
        self.name = name
        self.uuidString = uuidString
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let user = object as? User else {
            print("comparing object is not a User")
            return false
        }
        return name == user.name && uuidString == user.uuidString
    }
    
    override var description: String {
        return "User(name:\(name), uuidString: \(uuidString))"
    }
}
