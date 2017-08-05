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
import JASON

enum SuggestionOpenNowStatus: Int {
    case yes = 0
    case no = 1
    case unknown = 2
}

fileprivate let SuggestionOpenNowStatusYesKey = 0
fileprivate let SuggestionOpenNowStatusNoKey = 1
fileprivate let SuggestionOpenNowStatusUnknownKey = 2

extension JSONKeys {
    static let suggestionId = JSONKey<String>("id")
    static let suggestionName = JSONKey<String>("name")
    static let suggestionAddress = JSONKey<String>(path: "formatted_address")
    static let suggestionType = JSONKey<String>(path: "types", 0)
    static let suggestionRating = JSONKey<Double>("rating")
    static let suggestionLatitude = JSONKey<Double>(path: "geometry", "location", "lat")
    static let suggestionLongitude = JSONKey<Double>(path:
        "geometry", "location", "lng")
    static let suggestionPhoneNumber = JSONKey<String>("formatted_phone_number")
    static let suggestionWebsite = JSONKey<URL?>("website")
    static let suggestionSourceUrl = JSONKey<URL?>("url")
    static let suggestionIsOpenNow = JSONKey<Bool>(path: "opening_hours", "open_now")
    static let suggestionPhotos = JSONKey<[JSON]>(path: "photos")
    static let suggestionPhotosPhotoReference = JSONKey<String>("photo_reference")
}

class Suggestion: NSObject, NSCoding {
    
    var id: String
    var name: String
    var address: String
    var type: String
    var rating: Double
    var latitude: Double
    var longitude: Double
    var phoneNumber: String
    var website: URL?
    var sourceUrl: URL? // source of info
    var isOpenNow: Bool
    var photoIds: [String]
    var votes = 0
    var thumbnail: UIImage?
    
    init(id: String,
         name: String,
         address: String,
         type: String,
         rating: Double,
         latitude: Double,
         longitude: Double,
         phoneNumber: String,
         website: URL?,
         sourceUrl: URL?,
         isOpenNow: Bool,
         photoIds: [String]) {
        self.id = id
        self.name = name
        self.address = address
        self.type = type
        self.rating = rating
        self.latitude = latitude
        self.longitude = longitude
        self.phoneNumber = phoneNumber
        self.website = website
        self.sourceUrl = sourceUrl
        self.isOpenNow = isOpenNow
        self.photoIds = photoIds
    }
    
    init(_ json: JSON) {
        id = json[.suggestionId]
        name = json[.suggestionName]
        address = json[.suggestionAddress]
        type = json[.suggestionType].capitalized.replacingOccurrences(of: "_", with: " ")
        rating = json[.suggestionRating]
        latitude = json[.suggestionLatitude]
        longitude = json[.suggestionLongitude]
        phoneNumber = json[.suggestionPhoneNumber]
        website = json[.suggestionWebsite]
        sourceUrl = json[.suggestionSourceUrl]
        isOpenNow = json[.suggestionIsOpenNow]
        let photosJson = json[.suggestionPhotos].prefix(GoogleAPIConstants.maxPhotosToFetch)
        photoIds = photosJson.map { (json) -> String in
            return json[.suggestionPhotosPhotoReference]
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: "id") as? String else {
            return nil
        }
        guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
            return nil
        }
        guard let address = aDecoder.decodeObject(forKey: "address") as? String else {
            return nil
        }
        guard let type = aDecoder.decodeObject(forKey: "type") as? String else {
            return nil
        }
        guard let phoneNumber = aDecoder.decodeObject(forKey: "phoneNumber") as? String else {
            return nil
        }
        guard let photoIds = aDecoder.decodeObject(forKey: "photoIds") as? [String] else {
            return nil
        }
        
        rating = aDecoder.decodeDouble(forKey: "rating")
        latitude = aDecoder.decodeDouble(forKey: "latitude")
        longitude = aDecoder.decodeDouble(forKey: "longitude")
        if let website = aDecoder.decodeObject(forKey: "website") as? URL {
            self.website = website
        }
        if let sourceUrl = aDecoder.decodeObject(forKey: "sourceUrl") as? URL {
            self.sourceUrl = sourceUrl
        }
        isOpenNow = aDecoder.decodeBool(forKey: "isOpenNow")
        votes = aDecoder.decodeInteger(forKey: "votes")

        self.id = id
        self.name = name
        self.address = address
        self.type = type
        self.phoneNumber = phoneNumber
        self.photoIds = photoIds
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(address, forKey: "address")
        aCoder.encode(type, forKey: "type")
        aCoder.encode(rating, forKey: "rating")
        aCoder.encode(latitude, forKey: "latitude")
        aCoder.encode(longitude, forKey: "longitude")
        aCoder.encode(phoneNumber, forKey: "phoneNumber")
        if let website = website {
            aCoder.encode(website, forKey: "website")
        }
        if let sourceUrl = sourceUrl {
            aCoder.encode(sourceUrl, forKey: "sourceUrl")
        }
        aCoder.encode(isOpenNow, forKey: "isOpenNow")
        aCoder.encode(photoIds, forKey: "photoIds")
        aCoder.encode(votes, forKey: "votes")
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let suggestion = object as? Suggestion else {
            return false
        }
        return suggestion.id == id
    }

    override var hashValue: Int {
        return id.hashValue
    }

    override var description: String {
        return "Suggestion(name: \(name), number of votes: \(votes))"
    }

}
