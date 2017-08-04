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
    var suggestions: [Suggestion]
    
    init(type: Int, suggestions: [Suggestion]) {
        self.type = type
        self.suggestions = suggestions
    }
    
    required init?(coder aDecoder: NSCoder) {
        type = aDecoder.decodeInteger(forKey: "type")
        guard let suggestions = aDecoder.decodeObject(forKey: "suggestions") as? [Suggestion] else {
            print("operation has nil suggestions")
            return nil
        }
        self.suggestions = suggestions
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(type, forKey: "type")
        aCoder.encode(suggestions, forKey: "suggestions")
    }
    
}
