//
//  GoogleMapView.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-29.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import GoogleMaps

class GoogleMapView: GMSMapView {

    let mapsDefaultDistanceInMeters: Double = 400
    let mapsMaxDistanceInMeters: Double = 2000
    
    func setupMapView(at targetLocation: CLLocation, userLocation: CLLocation?) {
        self.isMyLocationEnabled = true
        
        var distanceFromUserLocation: CLLocationDistance
        if let userLocation = userLocation {
            distanceFromUserLocation = targetLocation.distance(from: userLocation)
            if distanceFromUserLocation > mapsMaxDistanceInMeters {
                distanceFromUserLocation = mapsDefaultDistanceInMeters
            }
        } else {
            distanceFromUserLocation = mapsDefaultDistanceInMeters
        }
        
        let coordinate = targetLocation.coordinate
        let zoom = GMSCameraPosition.zoom(at: coordinate, forMeters: distanceFromUserLocation * 2, perPoints: self.frame.size.height)
        self.camera = GMSCameraPosition(target: coordinate, zoom: zoom, bearing: 0, viewingAngle: 0)
        
        // create place marker
        let placeMarker =  GMSMarker(position: coordinate)
        placeMarker.map = self
    }

}
