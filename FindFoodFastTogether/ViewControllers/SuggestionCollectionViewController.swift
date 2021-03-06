//
//  SuggestionCollectionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-29.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreLocation

protocol SuggestionCollectionViewControllerDelegate: class {
    func didSelectSuggestionCell(suggestion: Suggestion, index: Int)
}

class SuggestionCollectionViewController: UICollectionViewController {

    dynamic var dataSource = [Suggestion]()
    weak var delegate: SuggestionCollectionViewControllerDelegate?
    var uniqueSuggestions = Set<Suggestion>()
    var isHosting: Bool!
    var searchClient = GoogleSearchClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func addSuggestion(_ suggestion: Suggestion) {
        // add suggestion only if the suggestion has not been 
        // suggested before
        if !uniqueSuggestions.contains(suggestion) {
            // add suggestion to unique suggestions
            uniqueSuggestions.insert(suggestion)
            
            dataSource.insert(suggestion, at: 0)
            collectionView?.reloadData()
        }
    }
    
    func sendAddedSuggestion(_ suggestion: Suggestion) {
        if isHosting {
            let peripheralManager = BluetoothPeripheralManager.sharedInstance
            peripheralManager.suggestions = dataSource
            peripheralManager.sendAddedNewSuggestion(suggestion)
        } else {
            BluetoothCentralManager.sharedInstance.sendHostNewSuggestion(suggestion: suggestion)
        }
    }
    
    func receivedAddedSuggestion(_ suggestion: Suggestion) {
        addSuggestion(suggestion)
        
        // notify users of added suggestion only if hosting
        if isHosting {
            sendAddedSuggestion(suggestion)
        }
    }
    
    func receivedSuggestionIdsToRemove(ids: [String]) {
        let idsSet = Set(ids)
        print("number of ids to remove: \(ids.count)")
        print("datasource count before: \(dataSource.count)")
        dataSource = dataSource.filter { (suggestion) -> Bool in
            let containsSuggestion = idsSet.contains(suggestion.id)
            // at the same time update unique suggestions ids list
            if containsSuggestion {
                uniqueSuggestions.remove(suggestion)
            }
            return !containsSuggestion
        }
        print("datasource count after: \(dataSource.count)")
        collectionView?.reloadData()
        if isHosting {
            let peripheralManager = BluetoothPeripheralManager.sharedInstance
            peripheralManager.suggestions = dataSource
            // tell all the other users that a suggestion was removed
            peripheralManager.sendRemoveSuggestionsIds(ids)
        }
    }

    func searchAndRemoveSuggestion(suggestionToRemove: Suggestion) {
        for (index, suggestion) in dataSource.enumerated() {
            if suggestion == suggestionToRemove {
                removeSuggestion(at: index)
            }
        }
    }
    
    func removeSuggestion(at index: Int) {
        let suggestionToRemove = dataSource[index]
        let suggestionIdToRemove = suggestionToRemove.id
        uniqueSuggestions.remove(suggestionToRemove)
        dataSource.remove(at: index)
        collectionView?.reloadData()
        if (isHosting) {
            let peripheralManager = BluetoothPeripheralManager.sharedInstance
            peripheralManager.sendRemoveSuggestionsIds([suggestionIdToRemove])
            peripheralManager.suggestions = dataSource
        } else {
            BluetoothCentralManager.sharedInstance.sendHostRemoveSuggestionIds([suggestionIdToRemove])
        }
    }
    
    @IBAction func removeSuggestion(_ sender: UIButton) {
        let index = sender.tag
        removeSuggestion(at: index)
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count == 0 ? 1 : dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: dataSource.count == 0 ? addNewSuggestionReuseIdentifier : suggestionReuseIdentifier, for: indexPath)
        
        if (dataSource.count > 0) {
            let suggestion = dataSource[indexPath.item]
            
            // regular suggestion cell
            let suggestionCell = cell as! SuggestionCollectionViewCell
            suggestionCell.title = suggestion.name
            suggestionCell.rating = suggestion.rating
            suggestionCell.subtitle = suggestion.type
            LocationManager.sharedInstance.requestLocation(completion: { (userLocation, error) in
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
                    print("returned location is nil")
                    return
                }
                let suggestionLocation = CLLocation(latitude: suggestion.latitude, longitude: suggestion.longitude)
                let distance = suggestionLocation.distance(from: userLocation) / 1000
                suggestionCell.distanceString = String(format: "%.1f km", distance)
            })
            // tag the button with the index path item, so we know
            // which suggestion to remove if tapped
            suggestionCell.removeButton.tag = indexPath.item
            if let thumbnail = suggestion.thumbnail {
                suggestionCell.image = thumbnail
            } else {
                suggestionCell.imageView.image = #imageLiteral(resourceName: "placeholderImage")
                if let firstPhotoId = suggestion.photos.first?.id {
                    let widthString = String(Int(suggestionCell.frame.width))
                    searchClient.fetchSuggestionPhoto(using: firstPhotoId, maxWidth: widthString, maxHeight: nil, completion: { [weak self] (image, error) in
                        guard error == nil else {
                            print("error fetching photo for suggestion cell")
                            return
                        }
                        guard let image = image else {
                            print("suggestion cell image is nil")
                            return
                        }
                        DispatchQueue.main.async { [weak self] in
                            guard let strongSelf = self else {
                                return
                            }
                            suggestionCell.image = image
                            
                            // update data source as well
                            strongSelf.dataSource[indexPath.item].thumbnail = image
                        }
                    })
                }
            }
        }
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // check that it's not the add suggestion prompt cell
        guard let _ = collectionView.cellForItem(at: indexPath) as? SuggestionCollectionViewCell else {
            return
        }
        let index = indexPath.item
        delegate?.didSelectSuggestionCell(suggestion: dataSource[index], index: index)
    }
}
