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
import INSPhotoGallery

class SuggestionDetailsViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var ratingView: UIStackView!
    @IBOutlet weak var ratingCosmosView: CosmosView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var suggestionTitlesView: UIStackView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var pageImageControl: UIPageControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var openNowButton: UIButton!
    @IBOutlet weak var openNowView: UIView!
    @IBOutlet weak var phoneNumberButton: UIButton!
    @IBOutlet weak var phoneNumberView: UIView!
    @IBOutlet weak var websiteButton: UIButton!
    @IBOutlet weak var websiteView: UIView!
    @IBOutlet weak var addSuggestionButton: UIButton!
    @IBOutlet weak var addSuggestionStackView: UIStackView!
    @IBOutlet weak var addSuggestionShadowView: UIView!
    @IBOutlet weak var attributionsView: UIView!
    @IBOutlet weak var attributionsTextView: UITextView!
    
    var partialSuggestion: PartialSuggestion!
    var suggestion: Suggestion!
    var userLocation: CLLocation?
    var searchClient = GoogleSearchClient()
    var pagedImageCollectionViewController: PagedImageCollectionViewController!
    
    // needed when coming from host view
    var isSuggestionAdded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // set textview delegate to handle URLs
        attributionsTextView.delegate = self

        if isSuggestionAdded {
            // change button to 'remove suggestion'
            addSuggestionButton.setTitle("Remove Suggestion", for: .normal)
            addSuggestionButton.backgroundColor = FindFoodFastColor.RedColor
        } else {
            addSuggestionButton.setTitle("Add Suggestion", for: .normal)
            addSuggestionButton.backgroundColor = FindFoodFastColor.MainColor
        }
        
        if suggestion != nil {
            // full details were already passed in no need to fetch from partial suggestion details
            updateUI(with: suggestion)
            
            // get images
            let widthString = String(Int(view.frame.width))
            let photos = suggestion.photos
            pagedImageCollectionViewController.dataSource = photos
            pagedImageCollectionViewController.collectionView?.reloadData()
            pagedImageCollectionViewController.insPhotos = [INSPhoto](repeating: INSPhoto(image: nil, thumbnailImage: nil), count: photos.count)
            fetchPhotosInOrder(widthString: widthString, photos: photos)
        } else {
            // get suggestion details
            searchClient.fetchSuggestionDetails(using: partialSuggestion.placeId) { [weak self] (suggestion, error) in
                guard error == nil, let suggestion = suggestion else {
                    print("error fetching suggestion details")
                    // pop view controller if details fail to load
                    self?.navigationController?.popViewController(animated: true)
                    return
                }
                guard let strongSelf = self else {
                    print("self is nil")
                    return
                }
                strongSelf.suggestion = suggestion
                let widthString = String(Int(strongSelf.view.frame.width))
                let photos = suggestion.photos.prefix(GoogleAPIConstants.maxPhotosToFetch)
                
                // update UI
                DispatchQueue.main.async(execute: { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.updateUI(with: suggestion)
                    strongSelf.pagedImageCollectionViewController.dataSource = Array(photos)
                    strongSelf.pagedImageCollectionViewController.collectionView?.reloadData()
                    strongSelf.pagedImageCollectionViewController.insPhotos = [INSPhoto](repeating: INSPhoto(image: nil, thumbnailImage: nil), count: photos.count)
                })
                
                // fetch photos
                strongSelf.fetchPhotosInOrder(widthString: widthString, photos: Array(photos))
            }
        }
    }
    
    func fetchPhotosInOrder(widthString: String, photos: [Photo]) {
        for (index, photo) in photos.enumerated() {
            let photoId = photo.id
            searchClient.fetchSuggestionPhoto(using: photoId, maxWidth: widthString, maxHeight: nil, completion: { [weak self] (image, error) in
                guard error == nil else {
                    print("error fetching photo \(photoId)")
                    return
                }
                guard let image = image else {
                    print("could not fetch image for suggestion for photo id: \(photoId)")
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    if self?.suggestion.thumbnail == nil {
                        self?.suggestion.thumbnail = image
                    }
                    
                    let insPhoto = INSPhoto(image: image, thumbnailImage: image)
                    if let htmlAttributionString = photo.htmlAttributions.first {
                        let htmlAttributedString = htmlAttributionString.htmlAttributedString
                        insPhoto.attributedTitle = htmlAttributedString
                    }
                    self?.pagedImageCollectionViewController.insPhotos[index] = insPhoto
                }
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        let shadowPath = UIBezierPath(rect: addSuggestionShadowView.bounds)
        addSuggestionShadowView.layer.masksToBounds = false
        addSuggestionShadowView.layer.shadowColor = UIColor.black.cgColor
        addSuggestionShadowView.layer.shadowOffset = CGSize(width: 0, height: -0.5)
        addSuggestionShadowView.layer.shadowOpacity = 0.3
        addSuggestionShadowView.layer.shadowPath = shadowPath.cgPath
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
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            print("segue for suggestion details vc has no identifier")
            return
        }
        switch segueIdentifier {
        case Segues.EmbedSuggestionImages:
            pagedImageCollectionViewController = segue.destination as! PagedImageCollectionViewController
            pagedImageCollectionViewController.delegate = self
            pagedImageCollectionViewController.searchClient = searchClient
        case Segues.UnwindToHostViewAfterAddingSuggestion:
            restoreNavigationBarAppearance()
        case Segues.UnwindToHostViewAfterRemovingSuggestion:
            restoreNavigationBarAppearance()
        case Segues.PresentMap:
            fallthrough
        case Segues.PresentMapFromMapView:
            let mapViewController = segue.destination as! MapViewController
            mapViewController.coordinate = CLLocationCoordinate2D(latitude: suggestion.latitude, longitude: suggestion.longitude)
            mapViewController.annotations = mapView.annotations
            
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
    
    func updateUI(with suggestion: Suggestion) {
        titleLabel.text = suggestion.name
        subtitleLabel.text = suggestion.type
        ratingCosmosView.rating = suggestion.rating
        ratingLabel.text = String(format: "%.1f", suggestion.rating)
        suggestionTitlesView.isHidden = false
        
        // set up map view
        let coordinate = CLLocationCoordinate2D(latitude: suggestion.latitude, longitude: suggestion.longitude)
        let placeAnnotation = MKPointAnnotation()
        placeAnnotation.coordinate = coordinate
        mapView.addAnnotation(placeAnnotation)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 500, 500)
        mapView.setRegion(region, animated: false)
        
        // calculate distance
        if let userLocation = userLocation {
            let suggestionLocation = CLLocation(latitude: suggestion.latitude, longitude: suggestion.longitude)
            let distance = userLocation.distance(from: suggestionLocation) / 1000
            let distanceString = String(format: "%.1f km", distance)
            distanceLabel.text = distanceString
            distanceLabel.isHidden = false
        } else {
            distanceLabel.isHidden = true
        }

        addressButton.setTitle(suggestion.address, for: .normal)
        
        if suggestion.isOpenNow {
            openNowButton.setTitle("Open", for: .normal)
        } else {
            openNowButton.setTitle("Closed", for: .normal)
        }
        
        if suggestion.phoneNumber.characters.count > 0 {
            phoneNumberButton.setTitle(suggestion.phoneNumber, for: .normal)
            phoneNumberView.isHidden = false
        } else {
            phoneNumberView.isHidden = true
        }
        
        if let website = suggestion.website {
            websiteButton.setTitle(website.absoluteString, for: .normal)
            websiteView.isHidden = false
        } else {
            websiteView.isHidden = true
        }
        
        if let attributionString = suggestion.htmlAttributions.first {
            attributionsTextView.attributedText = attributionString.htmlAttributedString
            attributionsView.isHidden = false
        } else {
            attributionsView.isHidden = true
        }
    }
    
    // MARK: - Handle button presses
    @IBAction func handleAddOrRemoveSuggestion(_ sender: UIButton) {
        if isSuggestionAdded {
            // remove suggestion
            performSegue(withIdentifier: Segues.UnwindToHostViewAfterRemovingSuggestion, sender: self)
        } else {
            performSegue(withIdentifier: Segues.UnwindToHostViewAfterAddingSuggestion, sender: self)
        }
    }
    @IBAction func handlePhoneNumber(_ sender: UIButton) {
        let formattedNumber = self.suggestion.phoneNumber.replacingOccurrences(of: "[ |()-]", with: "", options: [.regularExpression])
        guard let number = URL(string: "tel://" + formattedNumber) else {
            return
        }
        UIApplication.shared.open(number, options: [:], completionHandler: { (success) in
            if !success {
                print("failed to open phone number")
            }
        })
    }

    @IBAction func handleOpenWebsite(_ sender: UIButton) {
        guard let website = suggestion.website else {
            return
        }
        UIApplication.shared.open(website, options: [:]) { (success) in
            if !success {
                print("failed to open url")
            }
        }
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

extension SuggestionDetailsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // Make links clickable.
        return true
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
