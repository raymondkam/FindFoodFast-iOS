//
//  SuggestionDetailsViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-27.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import MapKit
import Cosmos

class SuggestionDetailsViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var ratingCosmosView: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var suggestionTitlesView: UIStackView!
    @IBOutlet weak var pageImageControl: UIPageControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var addSuggestionStackView: UIStackView!
    
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
        addSuggestionStackView.layer.masksToBounds = false;
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
                    let height = width * 10 / 16
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationBar = navigationController?.navigationBar {
            let transparentPixel = UIImage.imageWithColor(color: UIColor.clear)
            navigationBar.setBackgroundImage(transparentPixel, for: UIBarMetrics.default)
            navigationBar.shadowImage = transparentPixel
            navigationBar.backgroundColor = UIColor.clear
            navigationBar.isTranslucent = true
            navigationBar.tintColor = .white
            navigationBar.barStyle = .black
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavigationBarAppearance()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            print("segue for suggestion details vc has no identifier")
            return
        }
        switch segueIdentifier {
        case Segues.EmbedSuggestionImages:
            pagedImageCollectionViewController = segue.destination as! PagedImageCollectionViewController
            pagedImageCollectionViewController.delegate = self
        case Segues.UnwindToHostViewAfterAddingSuggestion:
            restoreNavigationBarAppearance()
        default:
            assert(false, "unexpected segue identifier \(segueIdentifier)")
        }
    }

    func restoreNavigationBarAppearance() {
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
            navigationBar.shadowImage = nil
            navigationBar.tintColor = FindFoodFastColor.MainColor
            navigationBar.barStyle = .default
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
        if let coordinate = suggestion.coordinate {
            let placeAnnotation = MKPointAnnotation()
            placeAnnotation.coordinate = coordinate
            mapView.addAnnotation(placeAnnotation)
            let region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500)
            mapView.showsUserLocation = true
            mapView.setRegion(region, animated: false)
        }
        if let address = suggestion.address {
            addressLabel.text = address
        }
        suggestionTitlesView.isHidden = false
    }
}

extension SuggestionDetailsViewController: PagedImageCollectionViewControllerDelegate {
    func pagedImageCollectionViewControllerUpdatedNumberOfImages(numberOfImages: Int) {
        pageImageControl.numberOfPages = numberOfImages
    }
    
    func pagedImageCollectionViewControllerScrollToItem(item: Int) {
        pageImageControl.currentPage = item
    }
}

extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}
