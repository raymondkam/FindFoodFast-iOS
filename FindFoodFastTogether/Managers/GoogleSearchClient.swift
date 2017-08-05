//
//  GoogleSearchClient.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-03.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire

struct GoogleAPIConstants {
    static let apiKey = GoogleWebAPIKey
    static let baseUrl = "https://maps.googleapis.com/maps/api/place/"
    static let textSearchUrl = baseUrl + "textsearch/json"
    static let nearbySearchUrl = baseUrl + "nearbysearch/json"
    static let placeDetailsUrl = baseUrl + "details/json"
    static let photoUrl = baseUrl + "photo"
    static let maxSearchResults = 20
    static let maxPhotosToFetch = 5
}

class GoogleSearchClient: SearchClient {
    
    func searchForNearbySuggestions(using keyword: String, location: CLLocationCoordinate2D, radiusInMeters: String, completion: @escaping ([PartialSuggestion]?, Error?) -> Void) {
        
        let parameters = [
            "key": GoogleAPIConstants.apiKey,
            "keyword": keyword,
            "name": keyword,
            "location": "\(location.latitude),\(location.longitude)",
            "rankby": "distance"
        ]
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        Alamofire.request(GoogleAPIConstants.nearbySearchUrl, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: nil)
            .responseJASON { (response) in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                switch response.result {
                case .success(let json):
                    let suggestionsJson = json["results"].prefix(GoogleAPIConstants.maxSearchResults)
                    let partialSuggestions = suggestionsJson.map(PartialSuggestion.init)
                    completion(partialSuggestions, nil)
                case .failure(let error):
                    completion(nil, error)
                }
        }
        
    }
    
    func fetchSuggestionDetails(using id: String, completion: @escaping (Suggestion?, Error?) -> Void) {
        
        let parameters = [
            "key": GoogleAPIConstants.apiKey,
            "placeid": id
        ]
        
        Alamofire.request(GoogleAPIConstants.placeDetailsUrl, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: nil).responseJASON { (response) in
            switch response.result {
            case .success(let json):
                let suggestionDetailsJson = json["result"]
                let suggestion = Suggestion(suggestionDetailsJson)
                completion(suggestion, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    func fetchSuggestionPhoto(using id: String, maxWidth: String?, maxHeight: String?, completion: @escaping (UIImage?, Error?) -> Void) {
        guard (maxWidth != nil && maxHeight == nil) || (maxWidth == nil && maxHeight != nil) else {
            print("cannot specify both max height and max width")
            return
        }
        
        var parameters = [
            "photoreference": id,
            "key": GoogleAPIConstants.apiKey
        ]
        
        if let maxWidth = maxWidth {
            parameters.updateValue(maxWidth, forKey: "maxwidth")
        }
        if let maxHeight = maxHeight {
            parameters.updateValue(maxHeight, forKey: "maxheight")
        }
        
        Alamofire.request(GoogleAPIConstants.photoUrl, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: nil).responseData { (response) in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    completion(image, nil)
                }
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
}
