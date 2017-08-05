//
//  SuggestionSearchResultsCollectionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-25.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreLocation

protocol SuggestionSearchResultsDelegate: class {
    func didSelectSuggestionFromSearchResults(partialSuggestion: PartialSuggestion)
}

class SuggestionSearchResultsCollectionViewController: UICollectionViewController {

    var userLocation: CLLocation?
    weak var delegate: SuggestionSearchResultsDelegate?
    
    var dataSource = [PartialSuggestion]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        let partialSuggestion = dataSource[indexPath.item]
        if let suggestionSearchResultCell = cell as? SuggestionSearchResultCollectionViewCell {
            suggestionSearchResultCell.title = partialSuggestion.name
            suggestionSearchResultCell.subtitle = partialSuggestion.closestAddress
            if let userLocation = userLocation {
                let distance = userLocation.distance(from: CLLocation(latitude: partialSuggestion.latitude, longitude: partialSuggestion.longitude)) / 1000
                suggestionSearchResultCell.distance = (String(format: "%.1f", distance), .kilometer)
            }
        }
    
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: poweredByGoogleFooterViewReuseIdentifer, for: indexPath)
            return footerView
        default:
            assert(false, "unexpected supplementary view for suggestion results collection view")
        }
    }
    
    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let partialSuggestion = dataSource[indexPath.item]
        delegate?.didSelectSuggestionFromSearchResults(partialSuggestion: partialSuggestion)
    }

}

extension SuggestionSearchResultsCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 50)
    }
    
}
