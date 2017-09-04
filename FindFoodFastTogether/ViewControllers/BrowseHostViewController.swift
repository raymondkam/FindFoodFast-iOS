//
//  BrowseHostViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-13.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreBluetooth
import PullToRefresh

class BrowseHostViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    
    var username: String?
    
    private var browseHostCollectionViewController: BrowseHostCollectionViewController!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Search"
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.scanHosts), name: NotificationNames.CentralBluetoothPoweredOn, object: nil)
        
        scanHosts()
    }
    
    @IBAction func unwindToBrowse(segue: UIStoryboardSegue) {
        // restore appearance of navigation for when unwinding 
        // from suggestion details
        navigationController?.isNavigationBarHidden = false
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
            navigationBar.shadowImage = nil
            navigationBar.tintColor = FindFoodFastColor.MainColor
            navigationBar.barStyle = .default
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NotificationNames.CentralBluetoothPoweredOn, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Segues.EmbedBrowseHostCollection:
            browseHostCollectionViewController = segue.destination as! BrowseHostCollectionViewController
            BluetoothCentralManager.sharedInstance.delegate = browseHostCollectionViewController
        default:
            print("unrecognized segue identifier")
        }
    }
    
    func scanHosts() {
        browseHostCollectionViewController.collectionView?.startRefreshing(at: .top)
        BluetoothCentralManager.sharedInstance.scanWithAutoStop(for: 30.0, completion: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.browseHostCollectionViewController.collectionView?.endRefreshing(at: .top)
        })
    }
}

