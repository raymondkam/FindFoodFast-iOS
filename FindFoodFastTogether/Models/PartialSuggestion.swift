//
//  PartialSuggestion.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-03.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import JASON

extension JSONKeys {
    static let partialSuggestionId = JSONKey<String>("id")
    static let partialSuggestionName = JSONKey<String>("name")
    static let partialSuggestionType = JSONKey<String>(path: "types", 0)
    static let partialSuggestionClosestAddress = JSONKey<String>(path: "vicinity")
    static let partialSuggestionLatitude = JSONKey<Double>(path: "geometry", "location", "lat")
    static let partialSuggestionLongitude = JSONKey<Double>(path: "geometry", "location", "lng")
    static let partialSuggestionPlaceId = JSONKey<String>("place_id")
}

class PartialSuggestion: NSObject, NSCoding {
    
    var id: String
    var name: String
    var closestAddress: String
    var type: String
    var latitude: Double
    var longitude: Double
    var placeId: String
    
    init(_ json: JSON) {
        id = json[.partialSuggestionId]
        name = json[.partialSuggestionName]
        closestAddress = json[.partialSuggestionClosestAddress]
        type = json[.partialSuggestionType]
        latitude = json[.partialSuggestionLatitude]
        longitude = json[.partialSuggestionLongitude]
        placeId = json[.partialSuggestionPlaceId]
    }
    
    required init?(coder aDecoder: NSCoder) {
        let funcName = "suggestion init decode: "
        guard let id = aDecoder.decodeObject(forKey: "id") as? String else {
            print(funcName + "could not decode id")
            return nil
        }
        
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
            print(funcName + "could not decode name")
            return nil
        }
        guard let closestAddress = aDecoder.decodeObject(forKey: "closestAddress") as? String else {
            print(funcName + "could not decode address")
            return nil
        }
        guard let type = aDecoder.decodeObject(forKey: "type") as? String else {
            print(funcName + "could not decode type")
            return nil
        }
        guard let placeId = aDecoder.decodeObject(forKey: "placeId") as? String else {
            print(funcName + "could not decode place id")
            return nil
        }
        self.id = id
        self.name = name
        self.closestAddress = closestAddress
        self.type = type
        self.placeId = placeId
        
        latitude = aDecoder.decodeDouble(forKey: "latitude")
        longitude = aDecoder.decodeDouble(forKey: "longitude")
        
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(closestAddress, forKey: "closestAddress")
        aCoder.encode(type, forKey: "type")
        aCoder.encode(latitude, forKey: "latitude")
        aCoder.encode(longitude, forKey: "longitude")
        aCoder.encode(placeId, forKey: "placeId")
    }
    
}
