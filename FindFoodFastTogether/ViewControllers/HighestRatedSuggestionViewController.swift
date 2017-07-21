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
    
    @IBOutlet weak var backgroundLabel: UILabel!
    @IBOutlet weak var cardTitle: UILabel!
    @IBOutlet weak var noImageLabel: UILabel!
    
    var highestRatedSuggestion: Suggestion!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardTitle.text = highestRatedSuggestion.name
        noImageLabel.text = highestRatedSuggestion.name
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

    @IBAction func handleDirectionsButtonPressed(_ sender: Any) {
        let coordinate = CLLocationCoordinate2DMake(43.6532, 79.3832)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = highestRatedSuggestion.name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }

}
