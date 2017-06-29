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
}

extension HostViewController : BluetoothPeripheralManagerDelegate {
    func bluetoothPeripheralManagerDidBecomeReadyToAdvertise(_: BluetoothPeripheralManager) {
        BluetoothPeripheralManager.sharedInstance.startAdvertising(hostname: hostname!)
    }
}
