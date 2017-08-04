//
//  Vote.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-04.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation

class Vote: NSObject, NSCoding {
    
    var suggestionId: String
    var score: Int
    
    init(suggestionId: String, score: Int) {
        self.suggestionId = suggestionId
        self.score = score
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let suggestionId = aDecoder.decodeObject(forKey: "suggestionId") as? String else {
            return nil
        }
        self.suggestionId = suggestionId
        score = aDecoder.decodeInteger(forKey: "score")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(suggestionId, forKey: "suggestionId")
        aCoder.encode(score, forKey: "score")
    }
    
}
