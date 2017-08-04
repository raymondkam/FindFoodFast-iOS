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
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Segues.AddSuggestionFromCell:
            fallthrough
        case Segues.AddSuggestionFromCellButton:
            (segue.destination as! AddSuggestionViewController).delegate = self
        default:
            print("unrecognized segue")
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
        }
    
        return cell
    }
}

extension SuggestionCollectionViewController: AddSuggestionDelegate {
    
    func didAddSuggestion(suggestion: Suggestion) {
        addSuggestion(suggestion: suggestion)
    }
    
    func isUniqueSuggestion(suggestion: Suggestion) -> Bool {
        return !uniqueSuggestions.contains(suggestion)
    }
    
}
