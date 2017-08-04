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
    @IBOutlet weak var websiteButton: UIButton!
    @IBOutlet weak var addSuggestionStackView: UIStackView!
    @IBOutlet weak var addSuggestionShadowView: UIView!
    @IBOutlet weak var attributionsView: UIView!
    @IBOutlet weak var attributionsTextView: UITextView!
    
    var partialSuggestion: PartialSuggestion!
    var suggestion: Suggestion!
    var locationManager = CLLocationManager()
    var userLocation: CLLocation?
    var searchClient = GoogleSearchClient()
    var pagedImageCollectionViewController: PagedImageCollectionViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

        // get suggestion details
        searchClient.fetchSuggestionDetails(using: partialSuggestion.placeId) { [weak self] (suggestion, error) in
            guard error == nil, let suggestion = suggestion else {
                print("error fetching suggestion details")
                // pop view controller if details fail to load
                self?.navigationController?.popViewController(animated: true)
                return
            }
            self?.suggestion = suggestion
            self?.updateUI(with: suggestion)
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
        case Segues.UnwindToHostViewAfterAddingSuggestion:
            restoreNavigationBarAppearance()
        case Segues.PresentMap:
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
        mapView.showsUserLocation = true
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
        
        phoneNumberButton.setTitle(suggestion.phoneNumber, for: .normal)
        
        if let website = suggestion.website {
            websiteButton.setTitle(website.absoluteString, for: .normal)
        }
        
    }
    
    // MARK: - Handle button presses
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
