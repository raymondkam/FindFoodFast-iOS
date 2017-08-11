//
//  Photo.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-11.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import JASON

extension JSONKeys {
    static let photoId = JSONKey<String>("photo_reference")
}

class Photo: NSObject, NSCoding {
    
    var id: String
    var htmlAttributions: [String]
    
    init(_ json: JSON) {
        id = json[.photoId]
        htmlAttributions = json["html_attributions"].arrayValue as! [String]
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: "id") as? String else {
            return nil
        }
        guard let htmlAttributions = aDecoder.decodeObject(forKey: "htmlAttributions") as? [String] else {
            return nil
        }
        self.id = id
        self.htmlAttributions = htmlAttributions
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(htmlAttributions, forKey: "htmlAttributions")
    }
    
}
