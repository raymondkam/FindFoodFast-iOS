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
    @IBOutlet weak var cardTitle: UILabel!
    @IBOutlet weak var cardSubtitle: UILabel!
    
    
    var highestRatedSuggestion: Suggestion!
    var isHosting: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        voteCountLabel.text = String(highestRatedSuggestion.votes)
        cardTitle.text = highestRatedSuggestion.name
        cardSubtitle.text = highestRatedSuggestion.type
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
