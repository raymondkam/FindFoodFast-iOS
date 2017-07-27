//
//  GoogleSuggestionSearchClient.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-25.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import GooglePlaces
import CoreLocation

let MeterInLatitude: Double = 1 / 111111

class GoogleSuggestionSearchClient: SuggestionSearchClient {
    
    private var placesClient = GMSPlacesClient()
    
    func coordinateBounds(from center:CLLocationCoordinate2D, meters: Double) -> GMSCoordinateBounds {
        // 1 unit = 111 km of latitude
        let offset = meters * MeterInLatitude
        let latMax = center.latitude + offset
        let latMin = center.latitude - offset
        
        let longOffset = offset * cos(center.latitude * Double.pi / 180.0);
        let longMax = center.longitude + longOffset
        let longMin = center.longitude - longOffset
        let maxCoordinate = CLLocationCoordinate2D(latitude: latMax, longitude: longMin)
        let minCoordinate = CLLocationCoordinate2D(latitude: latMin, longitude: longMax)
        
        return GMSCoordinateBounds(coordinate: maxCoordinate, coordinate: minCoordinate)
    }
    
    func searchForSuggestions(using query: String, coordinate: CLLocationCoordinate2D?, radiusInMeters: Int, completion: @escaping ([Suggestion]?, Error?) -> Void) {
        
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        
        var bounds: GMSCoordinateBounds?
        if let coordinate = coordinate {
            bounds = coordinateBounds(from: coordinate, meters: 10000)
        }
        
        placesClient.autocompleteQuery(query, bounds: bounds, filter: filter) { (predictions, error) in
            guard error == nil else {
                print("error occured while doing autocomplete query")
                return
            }
            guard let predictions = predictions else {
                print("predictions are nil")
                return
            }
            let suggestions = predictions.map({ (prediction) -> Suggestion in
                if let attributedSecondaryText = prediction.attributedSecondaryText {
                    return Suggestion(id: prediction.placeID,name: prediction.attributedPrimaryText.string, address: attributedSecondaryText.string, rating: nil)

                }
                return Suggestion(id: prediction.placeID,name: prediction.attributedPrimaryText.string, address: nil, rating: nil)
            })
            completion(suggestions, nil)
        }
        
    }
    
}
