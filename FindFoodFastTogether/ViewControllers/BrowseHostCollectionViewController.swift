//
//  BrowseHostCollectionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-06-13.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreBluetooth
import IGIdenticon

private let reuseIdentifier = "BrowseHostCell"

class BrowseHostCollectionViewController: UICollectionViewController {

    var dataSource = [Host]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Segues.JoinHost:
            BluetoothCentralManager.sharedInstance.delegate = (segue.destination as! HostViewController)
        default:
            print("segue identifier not recognized")
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let host = dataSource[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        let browseHostCell = cell as! BrowseHostCollectionViewCell
        browseHostCell.title = host.name
        browseHostCell.thumbnail = GitHubIdenticon().icon(from: host.peripheral.identifier.uuidString, size: CGSize(width: 64, height: 64))
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let host = dataSource[indexPath.item]
        BluetoothCentralManager.sharedInstance.connectToPeripheral(peripheral: host.peripheral)
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

extension BrowseHostCollectionViewController : BluetoothCentralManagerDelegate {
    func bluetoothCentralManagerDidDiscoverHost(_: BluetoothCentralManager, host: Host) {
        dataSource.append(host)
        collectionView?.reloadData()
    }
    
    func bluetoothCentralManagerDidConnectToHost(_: BluetoothCentralManager, users: [User]) {}
}

