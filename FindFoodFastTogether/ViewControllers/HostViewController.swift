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
    
    var hostname: String? // only set if you are hosting
    var username: String?
    
    var userCollectionViewController: UserCollectionViewController!
    
    @IBOutlet weak var userContainerViewHeightConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if hostname != nil {
            if BluetoothPeripheralManager.sharedInstance.isReadyToAdvertise {
                BluetoothPeripheralManager.sharedInstance.startAdvertising(hostname: hostname!)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isBeingDismissed || self.isMovingFromParentViewController {
            if hostname != nil {
                // stop advertising if host
                let peripheralManager = BluetoothPeripheralManager.sharedInstance
                peripheralManager.delegate = nil
                peripheralManager.stopAdvertising()
                peripheralManager.resetPeripheral()
            } else {
                // not a host, unsubscribe from characteristic
                let centralManager = BluetoothCentralManager.sharedInstance
                centralManager.delegate = nil
                centralManager.disconnectFromPeripheral()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier != nil else {
            print("segue has no identifier")
            return
        }
        switch segue.identifier! {
        case Segues.EmbedUserCollection:
            userCollectionViewController = (segue.destination as! UserCollectionViewController)
            userCollectionViewController.userContainerViewHeightConstraint = self.userContainerViewHeightConstraint
            if hostname != nil {
                let newUser = User(name: username!, uuidString: BluetoothPeripheralManager.sharedInstance.uuidString!)
                userCollectionViewController.dataSource.append(newUser)
            }
            
        default:
            print("segue not recognized")
        }
    }
}

extension HostViewController : BluetoothCentralManagerDelegate {
    func bluetoothCentralManagerDidDiscoverHost(_: BluetoothCentralManager, host: Host) {}
    
    func bluetoothCentralManagerDidConnectToHost(_: BluetoothCentralManager, users: [User]) {
        userCollectionViewController.dataSource = users
        userCollectionViewController.collectionView?.reloadData()
    }
}

extension HostViewController : BluetoothPeripheralManagerDelegate {
    func bluetoothPeripheralManagerDidBecomeReadyToAdvertise(_: BluetoothPeripheralManager) {
        BluetoothPeripheralManager.sharedInstance.startAdvertising(hostname: hostname!)
    }
    
    func bluetoothPeripheralManagerDidConnectWith(_: BluetoothPeripheralManager, newUser: User) {
        userCollectionViewController.dataSource.append(newUser)
        userCollectionViewController.collectionView?.reloadData()
    }
    
    func bluetoothPeripheralManagerDidDisconnectWith(_: BluetoothPeripheralManager, user: User) {
        let index = userCollectionViewController.dataSource.index(where: { (aUser) -> Bool in
            return aUser == user
        })!
        userCollectionViewController.dataSource.remove(at: index)
        userCollectionViewController.collectionView?.reloadData()
    }
}
