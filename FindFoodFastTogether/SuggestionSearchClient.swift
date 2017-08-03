//
//  SuggestionSearchClient.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-25.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import INSPhotoGallery

protocol SuggestionSearchClient {
    
    func searchForSuggestions(using query: String,
                              coordinate: CLLocationCoordinate2D?,
                              radiusInMeters: Int,
                              completion: @escaping (_ suggestions: [Suggestion]?, _ error: Error?) -> Void)
    
    func lookUpSuggestionDetails(using id:String, completion: @escaping (_ suggestions: Suggestion?, _ error: Error?) -> Void)
    
    func lookUpSuggestionPhotos(using suggestion: Suggestion, completion: @escaping (Suggestion?, Error?) -> Void)
    
    func lookUpSuggestionPhotos(using metadata:Any, size:CGSize?,
                                firstImage: @escaping (_ firstImage: INSPhoto?, _ error: Error?) -> Void,
                                completion: @escaping (_ remaningImages: [INSPhoto]?, _ error: Error?) -> Void)
}
