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
}

class GoogleSearchClient: SearchClient {
    
    func searchForSuggestions(using queryString: String, location: CLLocationCoordinate2D, radiusInMeters: String, completion: @escaping ([Suggestion]?, Error?) -> Void) {
        
        let parameters = [
            "key": GoogleAPIConstants.apiKey,
            "query": queryString,
            "location": "\(location.latitude),\(location.longitude)",
            "radius": radiusInMeters
        ]
        
        Alamofire.request(GoogleAPIConstants.textSearchUrl, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil)
            .responseJSON { (response) in
                switch response.result {
                case .success(let json):
                    guard let jsonDictionary = json as? [String: Any] else {
                        print("could not cast json as dictionary")
                        return
                    }
                    suggestions =
                    print("success")
                case .failure(let error):
                    completion(nil, error)
                }
            }
    }
    
    func fetchSuggestionDetails(using id: String, completion: @escaping (Suggestion?, Error?) -> Void) {

    }

    func fetchSuggestionPhoto(using id: String, completion: @escaping (UIImage?, Error?) -> Void) {
        
    }
    
}
