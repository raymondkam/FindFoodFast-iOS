//
//  BrowseHostViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-13.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreBluetooth

class BrowseHostViewController: UIViewController {
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    var username: String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = username
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.scanHosts), name: NotificationNames.BluetoothPoweredOn, object: nil)
        
        scanHosts()
    }
    
    func scanHosts() {
        BluetoothCentralManager.sharedInstance.scanWithAutoStop()
    }
    
    func showLoadingView() {
        self.loadingView.isHidden = false
        self.containerView.isHidden = true
    }
    
    func hideLoadingView() {
        self.loadingView.isHidden = true
        self.containerView.isHidden = false
    }
}

