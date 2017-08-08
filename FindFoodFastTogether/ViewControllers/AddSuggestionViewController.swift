//
//  AddSuggestionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreLocation

class AddSuggestionViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var loadingView: UIView!
    
    var suggestionSearchResultsCollectionViewController: SuggestionSearchResultsCollectionViewController!
    var suggestionDetailsViewController: SuggestionDetailsViewController!
    var searchClient: SearchClient = GoogleSearchClient()
    var userLocation: CLLocation?
    var searchWorkItem: DispatchWorkItem?
    
    let SuggestionTextFieldMinCharacterCount = 2
    let SuggestionTextFieldMaxCharacterCount = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        searchBar.becomeFirstResponder()
        
        LocationManager.sharedInstance.requestLocation { [weak self] (userLocation, error) in
            guard error == nil else {
                let locationError = error!
                let reason: String
                switch locationError {
                case .accessDenied:
                    reason = "access denied"
                case .notDetermined:
                    reason = "not determined"
                case .restricted:
                    reason = "restricted"
                }
                print("could not get location, reason: \(reason)")
                return
            }
            guard let userLocation = userLocation else {
                print("could not get location")
                return
            }
            self?.userLocation = userLocation
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
        // show indicator
        DispatchQueue.main.async { [weak self] in
            self?.loadingView.isHidden = false
        }
        
        print("search keyword: \(keyword)")
        var coordinate: CLLocationCoordinate2D
        if let userLocation = userLocation {
            coordinate = userLocation.coordinate
            suggestionSearchResultsCollectionViewController.userLocation = userLocation
            
            searchClient.searchForNearbySuggestions(using: keyword, location: coordinate, radiusInMeters: "50000", completion: { [weak self] (partialSuggestions, error) in
                guard keyword == self?.searchBar.text else {
                    print("current search bar text not the same current search term")
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.loadingView.isHidden = true
                }
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
