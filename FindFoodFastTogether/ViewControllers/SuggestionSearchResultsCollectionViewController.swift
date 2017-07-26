//
//  SuggestionSearchResultsCollectionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-25.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class SuggestionSearchResultsCollectionViewController: UICollectionViewController {

    var dataSource = [Suggestion]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: suggestionSearchResultReuseIdentifier, for: indexPath)
        let suggestion = dataSource[indexPath.item]
        if let suggestionSearchResultCell = cell as? SuggestionSearchResultCollectionViewCell {
            suggestionSearchResultCell.title = suggestion.name
            if let address = suggestion.address {
                suggestionSearchResultCell.subtitle = address
            }
            suggestionSearchResultCell.distance = nil
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate



}

extension SuggestionSearchResultsCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 64)
    }
    
}
