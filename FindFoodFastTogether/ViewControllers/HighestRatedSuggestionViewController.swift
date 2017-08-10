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
    
    var highestRatedSuggestion: Suggestion!
    var isHosting: Bool!
    var searchClient = GoogleSearchClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            if let firstPhotoId = highestRatedSuggestion.photoIds.first {
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
                    self?.highestRatedSuggestion.thumbnail = image
                })
            }

        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.4, delay: 1, options: .curveEaseInOut, animations: { [weak self] in
            self?.widthConstraint.constant = 337
            self?.heightConstraint.constant = (self?.stackView.frame.size.height)!
    
            self?.view.layoutIfNeeded()
            self?.suggestionCardView.alpha = 1
            self?.backgroundLabel.alpha = 0
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

    @IBAction func handleDirectionsButtonPressed(_ sender: Any) {
        let coordinate = CLLocationCoordinate2D(latitude: highestRatedSuggestion.latitude, longitude: highestRatedSuggestion.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = highestRatedSuggestion.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }

}
