//
//  AddSuggestionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-07.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreLocation
import NVActivityIndicatorView

class AddSuggestionViewController: UIViewController {
    
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicatorView: NVActivityIndicatorView!
    
    var suggestionSearchResultsCollectionViewController: SuggestionSearchResultsCollectionViewController!
    var suggestionDetailsViewController: SuggestionDetailsViewController!
    var searchClient: SearchClient = GoogleSearchClient()
    var userLocation: CLLocation?
    var searchWorkItem: DispatchWorkItem?
    
    let SuggestionTextFieldMinCharacterCount = 2
    let SuggestionTextFieldMaxCharacterCount = 80
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.delegate = self
        searchTextField.becomeFirstResponder()
        searchContainerView.addGradientLayer(colors: FindFoodFastColor.seaweedGradient.reversed(), at: 0)
        loadingView.addGradientLayer(colors: FindFoodFastColor.seaweedGradient.reversed(), at: 0)
        
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
    
    @IBAction func handleSearchTextFieldChanged(_ sender: UITextField) {
        guard let searchText = sender.text else {
            return
        }
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
    
    func searchNearbySuggestions(with keyword: String) {
        // show indicator
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicatorView.startAnimating()
            self?.loadingView.isHidden = false
        }
        
        print("search keyword: \(keyword)")
        var coordinate: CLLocationCoordinate2D
        if let userLocation = userLocation {
            coordinate = userLocation.coordinate
            suggestionSearchResultsCollectionViewController.userLocation = userLocation
            
            searchClient.searchForNearbySuggestions(using: keyword, location: coordinate, radiusInMeters: "50000", completion: { [weak self] (partialSuggestions, error) in
                guard keyword.lowercased() == self?.searchTextField.text?.lowercased() else {
                    print("current search bar text not the same current search term")
                    return
                }
                DispatchQueue.main.async { [weak self] in
                    self?.loadingView.isHidden = true
                    self?.activityIndicatorView.stopAnimating()
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

extension AddSuggestionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
