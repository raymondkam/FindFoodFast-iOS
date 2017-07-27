//
//  SuggestionSearchClient.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-25.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreLocation

protocol SuggestionSearchClient {
    
    func searchForSuggestions(using query: String,
                              coordinate: CLLocationCoordinate2D?,
                              radiusInMeters: Int,
                              completion: @escaping (_ suggestions: [Suggestion]?, _ error: Error?) -> Void)
}
