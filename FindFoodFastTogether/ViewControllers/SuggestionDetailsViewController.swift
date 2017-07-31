//
//  SuggestionDetailsViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-27.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import Cosmos

class SuggestionDetailsViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var ratingCosmosView: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var suggestionTitlesView: UIStackView!
    
    var suggestion: Suggestion!
    var searchClient = GoogleSuggestionSearchClient()
    var pagedImageCollectionViewController: PagedImageCollectionViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.ratingCosmosView.settings.fillMode = .half
        guard let id = suggestion.id else {
            print("suggestion has no id, cannot look up more details")
            return
        }
        searchClient.lookUpSuggestionDetails(using: id) { [weak self] (suggestion, error) in
            guard error == nil else {
                print("error: \(String(describing: error?.localizedDescription))")
                return
            }
            guard let suggestion = suggestion else {
                print("no error but suggestion returned is nil")
                return
            }
            self?.updateDetails(using: suggestion)
            
            // get photos
            self?.searchClient.lookUpSuggestionPhotos(using: suggestion, completion: { [weak self] (suggestion, error) in
                guard error == nil else {
                    print("error looking up suggestion photos")
                    return
                }
                guard let suggestionWithImageMetadata = suggestion else {
                    print("no error but no suggestion images")
                    return
                }
                let width = self?.view.frame.size.width
                if let width = width {
                    let height = width * 9 / 16
                    let size = CGSize(width: width, height: height)
                    self?.searchClient.lookUpSuggestionPhotos(using: suggestionWithImageMetadata.googlePhotosMetadataList as Any, size: size, completion: { [weak self] (images, error) in
                        if let images = images {
                            self?.pagedImageCollectionViewController.dataSource = images
                            self?.pagedImageCollectionViewController.collectionView?.reloadData()
                        }
                    })
                }

            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            print("segue for suggestion details vc has no identifier")
            return
        }
        switch segueIdentifier {
        case Segues.EmbedSuggestionImages:
            pagedImageCollectionViewController = segue.destination as! PagedImageCollectionViewController
        default:
            assert(false, "unexpected segue identifier \(segueIdentifier)")
        }
    }

    func updateDetails(using suggestion:Suggestion) {
        titleLabel.text = suggestion.name
        subtitleLabel.text = suggestion.type?.capitalized.replacingOccurrences(of: "_", with: " ")
        if let rating = suggestion.rating {
            ratingView.isHidden = false
            ratingCosmosView.rating = Double(rating)
            ratingLabel.text = String(format: "%.1f", rating)
        } else {
            ratingView.isHidden = true
        }
        suggestionTitlesView.isHidden = false
    }
}
