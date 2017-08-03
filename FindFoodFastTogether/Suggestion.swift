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

enum SuggestionOpenNowStatus: Int {
    case yes = 0
    case no = 1
    case unknown = 2
}

fileprivate let SuggestionOpenNowStatusYesKey = 0
fileprivate let SuggestionOpenNowStatusNoKey = 1
fileprivate let SuggestionOpenNowStatusUnknownKey = 2

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
    var isOpenNow: SuggestionOpenNowStatus?
    var phoneNumber: String?
    var thumbnail: UIImage?
    var voteRating = 0
    
    // google only data
    var googlePhotosMetadataList: GMSPlacePhotoMetadataList?
    
    init(id: String?, name: String, address: String?, rating: Float?, type: String?, coordinate: CLLocationCoordinate2D?, website: URL?, attributions: NSAttributedString?, isOpenNow: SuggestionOpenNowStatus?, phoneNumber: String?, voteRating: Int?) {
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
        if let phoneNumber = phoneNumber {
            self.phoneNumber = phoneNumber
        }
        if let voteRating = voteRating {
            self.voteRating = voteRating
        }
    }
    
    convenience init(id: String?, name: String, address: String?) {
        self.init(id: id, name: name, address: address, rating: nil, type: nil, coordinate: nil, website: nil, attributions: nil, isOpenNow: nil, phoneNumber: nil, voteRating: nil)
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
        
        if let type = aDecoder.decodeObject(forKey: "type") as? String {
            self.type = type
        }
        
        if let website = aDecoder.decodeObject(forKey: "website") as? URL {
            self.website = website
        }
        
        let latitude = aDecoder.decodeDouble(forKey: "latitude")
        let longitude = aDecoder.decodeDouble(forKey: "longitude")
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        if let attributions = aDecoder.decodeObject(forKey: "attributions") as? NSAttributedString {
            self.attributions = attributions
        }
        
        let isOpenNowKey = aDecoder.decodeInteger(forKey: "isOpenNow")
        switch isOpenNowKey {
        case SuggestionOpenNowStatusYesKey:
            self.isOpenNow = .yes
        case SuggestionOpenNowStatusNoKey:
            self.isOpenNow = .no
        case SuggestionOpenNowStatusUnknownKey:
            self.isOpenNow = .unknown
        default:
            assert(false, "unexpected value for decoding isOpenNow")
        }
        
        if let phoneNumber = aDecoder.decodeObject(forKey: "phoneNumber") as? String {
            self.phoneNumber = phoneNumber
        }
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
        if let type = type {
            aCoder.encode(type, forKey: "type")
        }
        aCoder.encode(website, forKey: "website")
        if let latitude = coordinate?.latitude {
            aCoder.encode(latitude, forKey: "latitude")
        }
        if let longitude = coordinate?.longitude {
            aCoder.encode(longitude, forKey: "longitude")
        }
        
        var encodedIsOpenNow: Int
        if let isOpenNow = isOpenNow {
            switch isOpenNow {
            case .yes:
                encodedIsOpenNow = SuggestionOpenNowStatusYesKey
            case .no:
                encodedIsOpenNow = SuggestionOpenNowStatusNoKey
            case .unknown:
                encodedIsOpenNow = SuggestionOpenNowStatusUnknownKey
            }
            aCoder.encode(encodedIsOpenNow, forKey: "isOpenNow")
        }
        
        aCoder.encode(attributions, forKey: "attributions")
        aCoder.encode(phoneNumber, forKey: "phoneNumber")
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
