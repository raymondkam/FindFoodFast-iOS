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
    static let maxSearchResults = 20
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
        
        Alamofire.request(GoogleAPIConstants.nearbySearchUrl, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil)
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
        
        Alamofire.request(GoogleAPIConstants.placeDetailsUrl, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseJASON { (response) in
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

    func fetchSuggestionPhoto(using id: String, completion: @escaping (UIImage?, Error?) -> Void) {
        
    }
    
}
