//
//  HostViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-14.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreBluetooth

class HostViewController: UIViewController {
    
    var hostname: String?
    var username: String?
    
    @IBOutlet weak var userContainerViewHeightConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (BluetoothPeripheralManager.sharedInstance.isReadyToAdvertise) {
            BluetoothPeripheralManager.sharedInstance.startAdvertising(hostname: hostname!)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isBeingDismissed || self.isMovingFromParentViewController {
            // stop advertising
            BluetoothPeripheralManager.sharedInstance.stopAdvertising()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Segues.EmbedUserCollection:
            (segue.destination as! UserCollectionViewController).userContainerViewHeightConstraint = self.userContainerViewHeightConstraint
        default:
            print("segue no recognized")
        }
    }
}

extension HostViewController : BluetoothPeripheralManagerDelegate {
    func bluetoothPeripheralManagerDidBecomeReadyToAdvertise(_: BluetoothPeripheralManager) {
        BluetoothPeripheralManager.sharedInstance.startAdvertising(hostname: hostname!)
    }
}
