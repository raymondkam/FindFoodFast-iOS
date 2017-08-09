//
//  LocationManager.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-08.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import Foundation
import CoreLocation

typealias LocationRequestBlock = (CLLocation?, LocationError?) -> Void

enum LocationError: Error {
    case accessDenied
    case notDetermined
    case restricted
}

class LocationManager: NSObject {
    
    private var locationManager = CLLocationManager()
    private let locationCacheTimeInterval: TimeInterval = 300
    
    fileprivate var _currentLocation: CLLocation?
    fileprivate var pendingRequestsBlocks = [LocationRequestBlock]()
    
    // singleton, private init
    private override init() {}
    
    static let sharedInstance: LocationManager = {
        let instance = LocationManager()
        instance.locationManager.delegate = instance
        instance.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        instance.locationManager.requestAlwaysAuthorization()
        return instance
    }()
    
    func requestLocation(completion: @escaping LocationRequestBlock) {
        // if there is a fresh location, then use it
        if let currentLocation = _currentLocation {
            let currentDate = Date()
            if currentDate < currentLocation.timestamp.addingTimeInterval(locationCacheTimeInterval) {
                // location was retrieved from less than 5 mins ago
                print("saved location is still relevant, no need to fetch new location")
                completion(currentLocation, nil)
                return
            }
        }
        
        locationManager.startUpdatingLocation()
        
        // add to pending request array, to be fulfilled when the 
        // location manager updates locations
        pendingRequestsBlocks.append(completion)
    }
    
    fileprivate func handlePendingRequestBlocks(location: CLLocation?, error: LocationError?) {
        if pendingRequestsBlocks.count == 0 {
            print("no location requests to fulfill")
            return
        }
        print("location manager has \(pendingRequestsBlocks.count) pending requests")
        if location != nil {
            for pendingRequestBlock in pendingRequestsBlocks {
                pendingRequestBlock(location, nil)
            }
        } else {
            for pendingRequestBlock in pendingRequestsBlocks {
                pendingRequestBlock(nil, error)
            }
        }
        pendingRequestsBlocks.removeAll(keepingCapacity: false)
    }
}

 extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("found some locations")
        guard locations.count > 0 else {
            print("did not find any locations")
            return
        }
        manager.stopUpdatingLocation()
        let bestLocation = locations[0]
        _currentLocation = bestLocation
        print("user coordinates: \(bestLocation.coordinate)")
        
        handlePendingRequestBlocks(location: bestLocation, error: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("authorized always")
        case .authorizedWhenInUse:
            print("clear to go use user location")
        case .denied:
            print("access denied")
            handlePendingRequestBlocks(location: nil, error: .accessDenied)
        case .notDetermined:
            print("not determined")
            handlePendingRequestBlocks(location: nil, error: .notDetermined)
        case .restricted:
            print("location restricted")
            handlePendingRequestBlocks(location: nil, error: .restricted)
        }
    }
}
