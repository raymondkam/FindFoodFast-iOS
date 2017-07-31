//
//  Suggestion.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import GooglePlaces

class Suggestion: NSObject, NSCoding {
    // id of the object can be used to fetch more details 
    // using the search client
    var id: String?
    var name: String
    var address: String?
    var rating: Float? // rating from search client
    var type: String? // food/restaurant type
    var coordinate: CLLocationCoordinate2D?
    var website: URL?
    var attributions: NSAttributedString?
    var isOpenNow: Bool?
    var voteRating = 0
    
    // google only data
    var googlePhotosMetadataList: GMSPlacePhotoMetadataList?

    init(id: String?, name: String, address: String?, rating: Float?, type: String?, coordinate: CLLocationCoordinate2D?, website: URL?, attributions: NSAttributedString?, isOpenNow: Bool?, voteRating: Int?) {
        self.id = id
        self.name = name
        self.address = address
        if let rating = rating {
            self.rating = rating
        }
        if let type = type {
            self.type = type
        }
        if let coordinate = coordinate {
            self.coordinate = coordinate
        }
        if let website = website {
            self.website = website
        }
        if let attributions = attributions {
            self.attributions = attributions
        }
        if let isOpenNow = isOpenNow {
            self.isOpenNow = isOpenNow
        }
        if let voteRating = voteRating {
            self.voteRating = voteRating
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let id = aDecoder.decodeObject(forKey: "id") as? String {
            self.id = id
        }
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
            print("suggestion init: could not decode name")
            return nil
        }
        if let address = aDecoder.decodeObject(forKey: "address") as? String {
            self.address = address
        }
        let rating = aDecoder.decodeFloat(forKey: "rating")
        self.rating = rating
        if let website = aDecoder.decodeObject(forKey: "website") as? URL {
            self.website = website
        }
        let latitude = aDecoder.decodeDouble(forKey: "latitude")
        let longitude = aDecoder.decodeDouble(forKey: "longitude")
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        if let attributions = aDecoder.decodeObject(forKey: "attributions") as? NSAttributedString {
            self.attributions = attributions
        }
        let isOpenNow = aDecoder.decodeBool(forKey: "isOpenNow")
        self.isOpenNow = isOpenNow
        let voteRating = aDecoder.decodeInteger(forKey: "voteRating")
        self.name = name
        self.voteRating = voteRating
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(address, forKey: "address")
        if let rating = rating {
            aCoder.encode(rating, forKey: "rating")
        }
        aCoder.encode(website, forKey: "website")
        if let latitude = coordinate?.latitude {
            aCoder.encode(latitude, forKey: "latitude")
        }
        if let longitude = coordinate?.longitude {
            aCoder.encode(longitude, forKey: "longitude")
        }
        aCoder.encode(attributions, forKey: "attributions")
        if let isOpenNow = isOpenNow {
            aCoder.encode(isOpenNow, forKey: "isOpenNow")
        }
        aCoder.encode(voteRating, forKey: "voteRating")
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
        return "Suggestion(name: \(name), rating: \(voteRating))"
    }
}
