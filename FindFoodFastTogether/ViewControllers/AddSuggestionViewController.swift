//
//  AddSuggestionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreLocation

protocol AddSuggestionDelegate: class {
    func didAddSuggestion(suggestion: Suggestion)
    func isUniqueSuggestion(suggestion: Suggestion) -> Bool
}

class AddSuggestionViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var suggestionSearchResultsCollectionViewController: SuggestionSearchResultsCollectionViewController!
    var suggestionDetailsViewController: SuggestionDetailsViewController!
    var locationManager = CLLocationManager()
    var searchClient: SearchClient = GoogleSearchClient()
    var userLocation: CLLocation?
    var searchWorkItem: DispatchWorkItem?
    weak var delegate: AddSuggestionDelegate?
    
    let SuggestionTextFieldMinCharacterCount = 2
    let SuggestionTextFieldMaxCharacterCount = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
        // load previously saved location and see if it is a 
        // recently fetched location
        let userDefaults = UserDefaults.standard
        if let cachedLocationData = userDefaults.data(forKey: UserDefaultsKeys.UserLocation) {
            print("loaded previously cached location")
            if let cachedLocation = NSKeyedUnarchiver.unarchiveObject(with: cachedLocationData) as? CLLocation {
                let currentDate = Date()
                if currentDate < cachedLocation.timestamp.addingTimeInterval(LocationCacheTimeInterval) {
                    // if cached location was retrieved less than 
                    // 5 mins ago
                    userLocation = cachedLocation
                }
            }
        }
        
        // set up location and get user's current location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        // only update location if cached location is bad
        if let _ = userLocation {} else {
            locationManager.startUpdatingLocation()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            print("not segue identifier")
            return
        }
        switch segueIdentifier {
        case Segues.EmbedSuggestionSearchResults:
            suggestionSearchResultsCollectionViewController = segue.destination as! SuggestionSearchResultsCollectionViewController
            suggestionSearchResultsCollectionViewController.delegate = self
        default:
            print("segue not identified")
        }
    }
    
    func searchNearbySuggestions(with keyword: String) {
        print("search keyword: \(keyword)")
        var coordinate: CLLocationCoordinate2D
        if let userLocation = userLocation {
            coordinate = userLocation.coordinate
            suggestionSearchResultsCollectionViewController.userLocation = userLocation
            
            searchClient.searchForNearbySuggestions(using: keyword, location: coordinate, radiusInMeters: "50000", completion: { [weak self] (partialSuggestions, error) in
                guard error == nil else {
                    print("error searching for nearby suggestions")
                    return
                }
                guard let partialSuggestions = partialSuggestions else {
                    print("suggestions from nearby search are nil")
                    return
                }
                self?.suggestionSearchResultsCollectionViewController.dataSource = partialSuggestions
                self?.suggestionSearchResultsCollectionViewController.collectionView?.reloadData()
            })
        }
    }
}

extension AddSuggestionViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("found some locations")
        guard locations.count > 0 else {
            print("did not find any locations")
            return
        }
        manager.stopUpdatingLocation()
        let bestLocation = locations[0]
        userLocation = bestLocation
        print("user coordinates: \(bestLocation.coordinate)")
        
        // save into user defaults
        let bestLocationData = NSKeyedArchiver.archivedData(withRootObject: bestLocation)
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(bestLocationData, forKey: UserDefaultsKeys.UserLocation)
        print("user location saved into user defaults")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("authorized always")
        case .authorizedWhenInUse:
            print("clear to go use user location")
        case .denied:
            print("access denied")
        case .notDetermined:
            print("not determined")
        case .restricted:
            print("location restricted")
        }
    }
}

extension AddSuggestionViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("change in search text")
        // to limit network activity, reload half a second after last key press.
        if let searchWorkItem = searchWorkItem {
            searchWorkItem.cancel()
        }
        if searchText.characters.count > 0 {
            let newSearchWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.searchNearbySuggestions(with: searchText)
            })
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5, execute: newSearchWorkItem)
            searchWorkItem = newSearchWorkItem
        } else {
            suggestionSearchResultsCollectionViewController.dataSource.removeAll()
            suggestionSearchResultsCollectionViewController.collectionView?.reloadData()
        }
    }
}

extension AddSuggestionViewController: SuggestionSearchResultsDelegate {
    func didSelectSuggestionFromSearchResults(partialSuggestion: PartialSuggestion) {
        guard let storyboardSuggestionDetailsViewController = storyboard?.instantiateViewController(withIdentifier: StoryboardIds.SuggestionDetails) as? SuggestionDetailsViewController else {
            print("could not create suggestion details vc with storyboard id")
            return
        }
        suggestionDetailsViewController = storyboardSuggestionDetailsViewController
        suggestionDetailsViewController.partialSuggestion = partialSuggestion
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        navigationController?.pushViewController(suggestionDetailsViewController, animated: true)
    }
}
