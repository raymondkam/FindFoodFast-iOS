//
//  SearchClient.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-03.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreLocation

protocol SearchClient {
    
    func searchForNearbySuggestions(using keyword: String, location: CLLocationCoordinate2D, radiusInMeters: String, completion: @escaping ([PartialSuggestion]?, Error?) -> Void)
    func fetchSuggestionDetails(using id: String, completion: @escaping(Suggestion?, Error?) -> Void)
    func fetchSuggestionPhoto(using id: String, maxWidth: String?, maxHeight: String?, completion: @escaping (UIImage?, Error?) -> Void)
    
}
