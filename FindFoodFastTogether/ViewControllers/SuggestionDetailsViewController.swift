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
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var pageImageControl: UIPageControl!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var openNowButton: UIButton!
    @IBOutlet weak var openNowView: UIView!
    @IBOutlet weak var phoneNumberButton: UIButton!
    @IBOutlet weak var websiteButton: UIButton!
    @IBOutlet weak var addSuggestionStackView: UIStackView!
    @IBOutlet weak var addSuggestionShadowView: UIView!
    @IBOutlet weak var attributionsView: UIView!
    @IBOutlet weak var attributionsTextView: UITextView!
    
    var suggestion: Suggestion!
    var locationManager = CLLocationManager()
    var userLocation: CLLocation?
    var searchClient = GoogleSuggestionSearchClient()
    var pagedImageCollectionViewController: PagedImageCollectionViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let id = suggestion.id else {
            print("suggestion has no id, cannot look up more details")
            return
        }
        
        // set up location and get user's current location
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        // load previously saved location and see if it is a
        // recently fetched location
        let userDefaults = UserDefaults.standard
        if let cachedLocationData = userDefaults.data(forKey: UserDefaultsKeys.UserLocation) {
            print("loaded previously cached location")
            if let cachedLocation = NSKeyedUnarchiver.unarchiveObject(with: cachedLocationData) as? CLLocation {
                let currentDate = Date()
                if currentDate < cachedLocation.timestamp.addingTimeInterval(LocationCacheTimeInterval) {
                    // if cached location was retrieved less than
                    // 5 mins ago
                    userLocation = cachedLocation
                }
            }
        }
        
        // only update location if cached location is bad
        if let _ = userLocation {} else {
            locationManager.startUpdatingLocation()
        }
        
        // set textview delegate to handle URLs
        attributionsTextView.delegate = self

        searchClient.lookUpSuggestionDetails(using: id) { [weak self] (suggestion, error) in
            guard error == nil else {
                print("error: \(String(describing: error?.localizedDescription))")
                return
            }
            guard let suggestion = suggestion else {
                print("no error but suggestion returned is nil")
                return
            }
            self?.suggestion = suggestion
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
                    let height = width * 2 / 3
                    let size = CGSize(width: width, height: height)
                    self?.searchClient.lookUpSuggestionPhotos(using: suggestionWithImageMetadata.googlePhotosMetadataList as Any, size: size, completion: { [weak self] (images, error) in
                        if let images = images {
                            self?.suggestion.thumbnail = images.first
                            self?.pagedImageCollectionViewController.dataSource = images
                            self?.pagedImageCollectionViewController.collectionView?.reloadData()
                        }
                    })
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
        subtitleLabel.text = suggestion.type
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
            addressButton.setTitle(address, for: .normal)
        }
        if let isOpenNow = suggestion.isOpenNow {
            if isOpenNow == .yes {
                openNowButton.setTitle("Open Now", for: .normal)
            } else if isOpenNow == .no {
                openNowButton.setTitle("Closed", for: .normal)
            } else {
                // unknown, remove row
                openNowView.isHidden = true
            }
        }
        if let phoneNumber = suggestion.phoneNumber {
            phoneNumberButton.setTitle(phoneNumber, for: .normal)
        }
        if let website = suggestion.website {
            websiteButton.setTitle(website.host, for: .normal)
        }
        if let userLocation = userLocation, let suggestionCoordinate = suggestion.coordinate {
            let suggestionLocation = CLLocation(latitude: suggestionCoordinate.latitude, longitude: suggestionCoordinate.longitude)
            let distance = userLocation.distance(from: suggestionLocation) / 1000
            let distanceString = String(format: "%.1f km", distance)
            distanceLabel.text = distanceString
            distanceLabel.isHidden = false
        } else {
            distanceLabel.isHidden = true
        }
        if let attributions = suggestion.attributions {
            attributionsTextView.attributedText = attributions
            adjustContentSize(textView: attributionsTextView)
            attributionsView.isHidden = false
        } else {
            attributionsView.isHidden = true
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

extension SuggestionDetailsViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("found some locations")
        guard locations.count > 0 else {
            print("did not find any locations")
            return
        }
        manager.stopUpdatingLocation()
        let bestLocation = locations[0]
        userLocation = bestLocation
        print("user coordinates: \(bestLocation.coordinate)")
        
        // save into user defaults
        let bestLocationData = NSKeyedArchiver.archivedData(withRootObject: bestLocation)
        let userDefaults = UserDefaults.standard
        userDefaults.setValue(bestLocationData, forKey: UserDefaultsKeys.UserLocation)
        print("user location saved into user defaults")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            print("authorized always")
        case .authorizedWhenInUse:
            print("clear to go use user location")
        case .denied:
            print("access denied")
        case .notDetermined:
            print("not determined")
        case .restricted:
            print("location restricted")
        }
    }
}

extension SuggestionDetailsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // Make links clickable.
        return true
    }
    
    // for centering a textview
    func adjustContentSize(textView: UITextView){
        let deadSpace = textView.bounds.size.height - textView.contentSize.height
        let inset = max(0, deadSpace/2.0)
        textView.contentInset = UIEdgeInsetsMake(inset, textView.contentInset.left, inset, textView.contentInset.right)
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
