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
            if (isHosting) {
                BluetoothPeripheralManager.sharedInstance.suggestions = dataSource
            } else {
                BluetoothCentralManager.sharedInstance.sendHostNewSuggestion(suggestion: suggestion)
            }
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
}
