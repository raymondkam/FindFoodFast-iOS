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
    var locationManager = CLLocationManager()
    var searchClient: SuggestionSearchClient!
    var userLocation: CLLocation!
    weak var delegate: AddSuggestionDelegate?
    
    let SuggestionTextFieldMinCharacterCount = 2
    let SuggestionTextFieldMaxCharacterCount = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
        // use google as search client
        searchClient = GoogleSuggestionSearchClient()
        
        // set up location and get user's current location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            print("not segue identifier")
            return
        }
        switch segueIdentifier {
        case Segues.EmbedSuggestionSearchResults:
            suggestionSearchResultsCollectionViewController = segue.destination as! SuggestionSearchResultsCollectionViewController
        default:
            print("segue not identified")
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
        userLocation = locations[0]
        print("user coordinates: \(userLocation.coordinate)")
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
        if searchText.characters.count > 0 {
            searchClient.searchForSuggestions(using: searchText, coordinate: userLocation.coordinate, radiusInMeters: 10000) { [weak self] (suggestions, error) in
                guard error == nil else {
                    print("error searching for suggestions")
                    return
                }
                guard let suggestions = suggestions else {
                    print("suggestions from search are nil")
                    return
                }
                guard searchText == self?.searchBar.text else {
                    // only update the results if the current 
                    // search text matches
                    return
                }
                self?.suggestionSearchResultsCollectionViewController.dataSource = suggestions
                self?.suggestionSearchResultsCollectionViewController.collectionView?.reloadData()
            }
        } else {
            suggestionSearchResultsCollectionViewController.dataSource.removeAll()
            suggestionSearchResultsCollectionViewController.collectionView?.reloadData()
        }
    }
}
