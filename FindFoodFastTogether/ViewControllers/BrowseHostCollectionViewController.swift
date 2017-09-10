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
import PullToRefresh

private let reuseIdentifier = "BrowseHostCell"

class BrowseHostCollectionViewController: UICollectionViewController {

    var dataSource = [Host]()
    
    private let pullToRefreshView = BluetoothPullToRefresh(height: 100, position: .top)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.delegate = self
        collectionView?.addPullToRefresh(pullToRefreshView, action: { [weak self] in
            
            self?.dataSource.removeAll()
            self?.collectionView?.reloadData()
            BluetoothCentralManager.sharedInstance.scanWithAutoStop(for: 30.0, completion: { [weak self] in
                self?.collectionView?.endRefreshing(at: .top)
            })
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case Segues.JoinHost:
            let hostViewController = segue.destination as! HostViewController
            BluetoothCentralManager.sharedInstance.delegate = hostViewController
            hostViewController.isHosting = false
        default:
            print("segue identifier not recognized")
        }
    }
    
    deinit {
        collectionView?.removePullToRefresh(pullToRefreshView)
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

}

extension BrowseHostCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 80)
    }
}

extension BrowseHostCollectionViewController : BluetoothCentralManagerDelegate {
    func bluetoothCentralManagerDidDiscoverHost(_: BluetoothCentralManager, host: Host) {
        dataSource.append(host)
        collectionView?.reloadData()
    }
    
    // unused
    func bluetoothCentralManagerDidConnectToHost(_: BluetoothCentralManager, users: [User]) {}
    func bluetoothCentralManagerDidDisconnectFromHost(_: BluetoothCentralManager) {}
    func bluetoothCentralManagerDidReceiveSuggestions(_: BluetoothCentralManager, suggestions: [Suggestion]) {}
    func bluetoothCentralManagerDidStartVoting(_: BluetoothCentralManager) {}
    func bluetoothCentralManagerDidReceiveHighestRatedSuggestion(_: BluetoothCentralManager, highestRatedSuggestion: Suggestion) {}
    func bluetoothCentralManagerDidReceiveAddedSuggestion(_: BluetoothCentralManager, suggestion: Suggestion) {}
    func bluetoothCentralManagerDidReceiveSuggestionIdsToRemove(_: BluetoothCentralManager, suggestionIds: [String]) {}
}

