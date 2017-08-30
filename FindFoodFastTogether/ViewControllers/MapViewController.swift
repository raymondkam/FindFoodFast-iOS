//
//  MapViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-08-02.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: GoogleMapView!
    
    var targetLocation: CLLocation!
    var userLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.setupMapView(at: targetLocation, userLocation: userLocation)
        mapView.settings.myLocationButton = true
    }

    @IBAction func dismissMapView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
