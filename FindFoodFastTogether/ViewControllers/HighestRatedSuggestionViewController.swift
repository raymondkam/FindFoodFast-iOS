//
//  HighestRatedSuggestionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-20.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import MapKit

class HighestRatedSuggestionViewController: UIViewController {
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var suggestionCardView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var voteCountLabel: UILabel!
    @IBOutlet weak var backgroundLabel: UILabel!
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardSubtitleLabel: UILabel!
    @IBOutlet weak var cardDistanceLabel: UILabel!
    
    // used for fixing the size of card
    @IBOutlet weak var scoreLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scoreTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    var highestRatedSuggestion: Suggestion!
    var isHosting: Bool!
    var searchClient = GoogleSearchClient()
    
    private var installedNavigationApps = ["Apple Maps"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCardMargins()
        checkInstalledNavigationApps()
        
        LocationManager.sharedInstance.requestLocation { [weak self] (userLocation, error) in
            guard error == nil else {
                print("error requesting location in highest rated suggestion")
                return
            }
            guard let strongSelf = self else {
                print("highest rated suggestion: no strong reference to self")
                return
            }
            guard let userLocation = userLocation else {
                print("highest rated suggestion: location returned is nil")
                return
            }
            let suggestionLocation = CLLocation(latitude: strongSelf.highestRatedSuggestion.latitude, longitude: strongSelf.highestRatedSuggestion.longitude)
            let distanceInMeters = suggestionLocation.distance(from: userLocation) / 1000
            strongSelf.cardDistanceLabel.text = String(format: "%.1f km", distanceInMeters)
            strongSelf.cardDistanceLabel.isHidden = false
        }
        
        voteCountLabel.text = String(highestRatedSuggestion.votes)
        cardTitleLabel.text = highestRatedSuggestion.name
        cardSubtitleLabel.text = highestRatedSuggestion.type
        if let thumbnail = highestRatedSuggestion.thumbnail {
            imageView.image = thumbnail
        } else {
            imageView.image = #imageLiteral(resourceName: "placeholderImage")
            if let firstPhotoId = highestRatedSuggestion.photos.first?.id {
                let widthString = String(Int(imageView.frame.width))
                searchClient.fetchSuggestionPhoto(using: firstPhotoId, maxWidth: widthString, maxHeight: nil, completion: { [weak self] (image, error) in
                    guard error == nil else {
                        print("error fetching photo for suggestion cell")
                        return
                    }
                    guard let image = image else {
                        print("suggestion cell image is nil")
                        return
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else {
                            print("no reference to self")
                            return
                        }
                        UIView.transition(with: strongSelf.imageView,
                                          duration: 0.3,
                                          options: .transitionCrossDissolve,
                                          animations: {
                                            strongSelf.imageView.image = image
                        },
                                          completion: nil)
                        
                        // update data source as well
                        strongSelf.highestRatedSuggestion.thumbnail = image
                    }
                })
            }

        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.4, delay: 1, options: .curveEaseInOut, animations: { [weak self] in
            guard let strongSelf = self else {
                print("no reference to self")
                return
            }
            let width = min(337, strongSelf.view.frame.width - 20)
            strongSelf.widthConstraint.constant = width
            strongSelf.heightConstraint.constant = strongSelf.stackView.frame.size.height
    
            strongSelf.view.layoutIfNeeded()
            strongSelf.suggestionCardView.alpha = 1
            strongSelf.backgroundLabel.alpha = 0
        }) { (completed) in
            if completed {
                print("animation complete")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            print("no segue identifier")
            return
        }
        if segueIdentifier == Segues.UnwindToStart {
            // do clean up of BT managers
            if (isHosting) {
                BluetoothPeripheralManager.sharedInstance.clearPeripheralData()
            } else {
                BluetoothCentralManager.sharedInstance.disconnectFromPeripheral()
            }
        }
    }
    
    func setupCardMargins() {
        // calculate correct margins for card
        let width = min(337, view.frame.size.width - 20)
        let cardLeftRightMargins = (view.frame.size.width - width) / 2
        let photoLeftRightMargins = cardLeftRightMargins + 10
        
        scoreLeadingConstraint.constant = cardLeftRightMargins
        scoreTrailingConstraint.constant = cardLeftRightMargins
        imageViewLeadingConstraint.constant = photoLeftRightMargins
        imageViewTrailingConstraint.constant = photoLeftRightMargins
    }
    
    func checkInstalledNavigationApps() {
        if UIApplication.shared.canOpenURL(URL(string: NavigationAppScheme.googleMaps)!) {
            installedNavigationApps.append("Google Maps")
        }
        
        if UIApplication.shared.canOpenURL(URL(string: NavigationAppScheme.waze)!) {
            installedNavigationApps.append("Waze")
        }
    }
    
    func handleDirectionsActionSheet(action: UIAlertAction) {
        let actionTitle = action.title!
        let coordinate = CLLocationCoordinate2D(latitude: highestRatedSuggestion.latitude, longitude: highestRatedSuggestion.longitude)
        switch actionTitle {
        case "Apple Maps":
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
            mapItem.name = highestRatedSuggestion.name
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        case "Google Maps":
            let googleURLString = String(format: "%@?directionsmode=driving&daddr=%f,%f", NavigationAppScheme.googleMaps, highestRatedSuggestion.latitude, highestRatedSuggestion.longitude)
            let googleURL = URL(string: googleURLString)!
            UIApplication.shared.open(googleURL, options: [:], completionHandler: nil)
        case "Waze":
            let wazeURLString = String(format: "%@?ll=%f,%f&navigate=yes", NavigationAppScheme.waze, highestRatedSuggestion.latitude, highestRatedSuggestion.longitude).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let wazeURL = URL(string: wazeURLString)!
            UIApplication.shared.open(wazeURL, options: [:], completionHandler: nil)
        default:
            assert(false, "Unhandled directions action sheet action")
        }
    }

    @IBAction func handleDirectionsButtonPressed(_ sender: Any) {
        let actionController = UIAlertController(title: "Directions", message: "Which app would you like to use?", preferredStyle: .actionSheet)
        actionController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        for navigationApp in installedNavigationApps {
            let action = UIAlertAction(title: navigationApp, style: .default, handler: handleDirectionsActionSheet)
            actionController.addAction(action)
        }
        present(actionController, animated: true, completion: nil)
    }

}
