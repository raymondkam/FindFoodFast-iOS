//
//  SuggestionCollectionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-29.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class SuggestionCollectionViewController: UICollectionViewController {

    dynamic var dataSource = [Suggestion]()
    var uniqueSuggestions = Set<Suggestion>()
    var isHosting: Bool!
    var searchClient = GoogleSearchClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func addSuggestion(suggestion: Suggestion) {
        // add suggestion only if the suggestion has not been 
        // suggested before
        if !uniqueSuggestions.contains(suggestion) {
            // add suggestion to unique suggestions
            uniqueSuggestions.insert(suggestion)
            
            dataSource.insert(suggestion, at: 0)
            collectionView?.reloadData()
            
            // also update host
            if isHosting {
                let peripheralManager = BluetoothPeripheralManager.sharedInstance
                peripheralManager.suggestions = dataSource
                peripheralManager.sendAddedNewSuggestion(suggestion)
                
            } else {
                BluetoothCentralManager.sharedInstance.sendHostNewSuggestion(suggestion: suggestion)
            }
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

    @IBAction func removeSuggestion(_ sender: UIButton) {
        let index = sender.tag
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
            // tag the button with the index path item, so we know
            // which suggestion to remove if tapped
            suggestionCell.removeButton.tag = indexPath.item
            if let thumbnail = suggestion.thumbnail {
                suggestionCell.image = thumbnail
            } else {
                if let firstPhotoId = suggestion.photoIds.first {
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
                        suggestionCell.image = image
                        
                        // update data source as well
                        self?.dataSource[indexPath.item].thumbnail = image
                    })
                }
            }
        }
    
        return cell
    }
}
