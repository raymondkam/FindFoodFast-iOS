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
    
    @IBOutlet weak var mapView: MKMapView!
    
    var annotations: [MKAnnotation]!
    var coordinate: CLLocationCoordinate2D!

    override func viewDidLoad() {
        super.viewDidLoad()
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000)
        mapView.addAnnotations(annotations)
        mapView.showsUserLocation = true
        mapView.setRegion(region, animated: false)
    }

    @IBAction func dismissMapView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
