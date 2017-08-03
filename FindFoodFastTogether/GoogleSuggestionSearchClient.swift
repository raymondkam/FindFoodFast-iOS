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
import INSPhotoGallery

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
                    return Suggestion(id: prediction.placeID, name: prediction.attributedPrimaryText.string, address: attributedSecondaryText.string)

                }
                return Suggestion(id: prediction.placeID, name: prediction.attributedPrimaryText.string, address: nil)
            })
            completion(suggestions, nil)
        }
        
    }
    
    func lookUpSuggestionDetails(using id: String, completion: @escaping (Suggestion?, Error?) -> Void) {
        
        placesClient.lookUpPlaceID(id) { (place, error) in
            guard error == nil else {
                print("google places error looking up more place details")
                completion(nil, error)
                return
            }
            guard let place = place else {
                print("google place is nil")
                return
            }
            var openNowStatus: SuggestionOpenNowStatus
            let placeOpenNowStatus = place.openNowStatus
            
            if placeOpenNowStatus == .yes {
                openNowStatus = .yes
            } else if placeOpenNowStatus == .no {
                openNowStatus = .no
            } else {
                openNowStatus = .unknown
            }
            
            let suggestion = Suggestion(id: place.placeID, name: place.name, address: place.formattedAddress, rating: place.rating, type: place.types.first?.capitalized.replacingOccurrences(of: "_", with: " "), coordinate: place.coordinate, website: place.website, attributions: place.attributions, isOpenNow: openNowStatus, phoneNumber: place.phoneNumber, voteRating: nil)
            completion(suggestion, nil)
        }
    }
    
    func lookUpSuggestionPhotos(using suggestion: Suggestion, completion: @escaping (Suggestion?, Error?) -> Void) {
        guard let id = suggestion.id else {
            print("suggestion has no id, cannot look up photos")
            return
        }
        placesClient.lookUpPhotos(forPlaceID: id) { (photosMetadata, error) in
            guard error == nil else {
                print("error looking up place photos \(String(describing: error?.localizedDescription))")
                completion(nil, error)
                return
            }
            suggestion.googlePhotosMetadataList = photosMetadata
            completion(suggestion, nil)
        }
    }
    
    func lookUpSuggestionPhotos(using metadata:Any, size:CGSize?, completion: @escaping (_ images: [INSPhoto]?, _ error: Error?) -> Void) {
        guard let googlePhotosMetadataList = metadata as? GMSPlacePhotoMetadataList else {
            print("wrong format of googles photo metadata")
            return
        }
        
        var images = [INSPhoto]()
        
        guard googlePhotosMetadataList.results.count > 0 else {
            print("no photos in photos metadata")
            completion(images, nil)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        let photos = googlePhotosMetadataList.results
        let count = min(photos.count, 5)
        
        // take the first 5 photos max
        for photo in googlePhotosMetadataList.results.prefix(upTo: count) {
            var photoAttributions: NSAttributedString?
            if let editPhotoAttributions = photo.attributions {
                let mutableAttributions = NSMutableAttributedString(attributedString: editPhotoAttributions)
                let range = NSMakeRange(0, editPhotoAttributions.length)
                mutableAttributions.addAttribute(NSForegroundColorAttributeName, value: UIColor.white, range: range)
                photoAttributions = mutableAttributions
            }
            
            dispatchGroup.enter()
            if let size = size {
                placesClient.loadPlacePhoto(photo, constrainedTo: size, scale: 1, callback: { (image, error) in
                    dispatchGroup.leave()
                    guard error == nil else {
                        print("error fetching suggestion image")
                        return
                    }
                    if let image = image {
                        let insPhoto = INSPhoto(image: image, thumbnailImage: image)
                        insPhoto.attributedTitle = photoAttributions
                        images.append(insPhoto)
                    }
                })
            } else {
                placesClient.loadPlacePhoto(photo, callback: { (image, error) in
                    dispatchGroup.leave()
                    guard error == nil else {
                        print("error fetching suggestion image")
                        return
                    }
                    if let image = image {
                        let insPhoto = INSPhoto(image: image, thumbnailImage: image)
                        insPhoto.attributedTitle = photoAttributions
                        images.append(insPhoto)
                    }
                })
            }
        }
        
        dispatchGroup.notify(queue: .main) { 
            completion(images, nil)
        }
        
    }
}
