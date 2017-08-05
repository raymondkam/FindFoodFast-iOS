//
//  SuggestionOperation.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-04.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation

struct SuggestionOperationType {
    static let Add = 0
    static let Remove = 1
    static let All = 2
}

class SuggestionOperation: NSObject, NSCoding {
    
    var type: Int
    var data: Data
    
    init(type: Int, data: Data) {
        self.type = type
        self.data = data
    }
    
    required init?(coder aDecoder: NSCoder) {
        type = aDecoder.decodeInteger(forKey: "type")
        guard let data = aDecoder.decodeObject(forKey: "data") as? Data else {
            print("operation has nil data")
            return nil
        }
        self.data = data
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(type, forKey: "type")
        aCoder.encode(data, forKey: "data")
    }
    
}
