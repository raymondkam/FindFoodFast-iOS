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
    
    var isHosting: Bool!
    var hostname: String? // only set if you are hosting
    var username: String?
    
    @IBOutlet weak var numberOfSuggestionsLabel: UILabel!
    @IBOutlet weak var numberOfUsersLabel: UILabel!
    
    private var hasEnoughUsers = false
    private var hasEnoughSuggestions = false
    
    fileprivate var suggestionCollectionViewController: SuggestionCollectionViewController!
    fileprivate var userCollectionViewController: UserCollectionViewController!
    fileprivate var suggestionDetailsViewController: SuggestionDetailsViewController!
    
    @IBOutlet weak var userContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var startButton: UIBarButtonItem!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG
            hasEnoughUsers = true
        #endif
        
        if isHosting {
            if BluetoothPeripheralManager.sharedInstance.isReadyToAdvertise {
                BluetoothPeripheralManager.sharedInstance.startAdvertising(hostname: hostname!)
            }
        } else {
            // remove the start button if not host
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard isHosting else {
            print("should not get here if not hosting")
            return
        }
        if object as? UserCollectionViewController == userCollectionViewController {
            if keyPath == "dataSource" {
                if let connectedUsers = change?[.newKey] as? [User] {
                    numberOfUsersLabel.text = String(format: "(%i)", connectedUsers.count)
                    
                    if connectedUsers.count > 1 {
                        hasEnoughUsers = true
                    }
                } else {
                    #if DEBUG
                        hasEnoughUsers = true
                    #else
                        hasEnoughUsers = false
                    #endif
                }
            }
        } else if object as? SuggestionCollectionViewController == suggestionCollectionViewController {
            if keyPath == "dataSource" {
                if let suggestions = change?[.newKey] as? [Suggestion] {
                    if suggestions.count > 0 {
                        numberOfSuggestionsLabel.text = String(format: "(%i)", suggestions.count)
                    } else {
                        numberOfSuggestionsLabel.text = ""
                    }
                    
                    if suggestions.count > 1 {
                        hasEnoughSuggestions = true
                    }
                } else {
                    hasEnoughSuggestions = false
                }
            }
        }
        if hasEnoughUsers && hasEnoughSuggestions {
            startButton.isEnabled = true
        } else {
            startButton.isEnabled = false
        }
    }
    
    deinit {
        if isHosting {
            userCollectionViewController.removeObserver(self, forKeyPath: "dataSource")
            suggestionCollectionViewController.removeObserver(self, forKeyPath: "dataSource")
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if self.isBeingDismissed || self.isMovingFromParentViewController {
            if isHosting {
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
        guard let identifier = segue.identifier else {
            print("segue has no identifier")
            return
        }
        switch identifier {
        case Segues.EmbedUserCollection:
            userCollectionViewController = (segue.destination as! UserCollectionViewController)
            userCollectionViewController.userContainerViewHeightConstraint = self.userContainerViewHeightConstraint
            if isHosting {
                let newUser = User(name: username!, uuidString: Bluetooth.deviceUuidString!)
                userCollectionViewController.dataSource.append(newUser)
                userCollectionViewController.addObserver(self, forKeyPath: "dataSource", options: .new, context: nil)
            }
        case Segues.EmbedSuggestionCollection:
            suggestionCollectionViewController = segue.destination as! SuggestionCollectionViewController
            suggestionCollectionViewController.delegate = self
            suggestionCollectionViewController.isHosting = isHosting
            if isHosting {
                suggestionCollectionViewController.addObserver(self, forKeyPath: "dataSource", options: .new, context: nil)
            }
        case Segues.StartVoting:
            guard let voteViewController = segue.destination as? VoteViewController else {
                print("destination controller is not a vote view controller")
                return
            }
            if isHosting {
                let peripheralManager = BluetoothPeripheralManager.sharedInstance
                // stop advertising to stop other people from 
                // joining while voting is in progress
                peripheralManager.stopAdvertising()
                peripheralManager.startVoting()
                peripheralManager.delegate = voteViewController
            } else {
                BluetoothCentralManager.sharedInstance.delegate = voteViewController
            }
            // Pass on the suggestions to be voted on
            voteViewController.dataSource = suggestionCollectionViewController.dataSource
            voteViewController.isHosting = isHosting
        default:
            print("segue not recognized")
        }
    }
    
    @IBAction func unwindToHostViewAfterAddingSuggestion(segue: UIStoryboardSegue) {
        guard let suggestion = (segue.source as? SuggestionDetailsViewController)?.suggestion else {
            print("cannot get suggestion from suggestion details vc")
            return
        }
        suggestionCollectionViewController.addSuggestion(suggestion)
        suggestionCollectionViewController.sendAddedSuggestion(suggestion)
    }
    
    @IBAction func unwindToHostViewAfterRemovingSuggestion(segue: UIStoryboardSegue) {
        guard let suggestionDetailsViewController = segue.source as? SuggestionDetailsViewController else {
            return
        }
        guard let suggestion = suggestionDetailsViewController.suggestion else {
            print("cannot get suggestion from suggestion details vc")
            return
        }
        // remove suggestion
        suggestionCollectionViewController.searchAndRemoveSuggestion(suggestionToRemove: suggestion)
    }
}

extension HostViewController: SuggestionCollectionViewControllerDelegate {
    func didSelectSuggestionCell(suggestion: Suggestion, index: Int) {
        guard let storyboardSuggestionDetailsViewController = storyboard?.instantiateViewController(withIdentifier: StoryboardIds.SuggestionDetails) as? SuggestionDetailsViewController else {
            print("could not create suggestion details vc with storyboard id")
            return
        }
        suggestionDetailsViewController = storyboardSuggestionDetailsViewController
        suggestionDetailsViewController.suggestion = suggestion
        suggestionDetailsViewController.isSuggestionAdded = true
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        navigationController?.pushViewController(suggestionDetailsViewController, animated: true)
    }
}

extension HostViewController : BluetoothCentralManagerDelegate {
    func bluetoothCentralManagerDidDisconnectFromHost(_: BluetoothCentralManager) {
        let alert = UIAlertController(title: nil, message: "Disconnected from Host", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (alert) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.performSegue(withIdentifier: Segues.UnwindToBrowse, sender: strongSelf)
        }))
        present(alert, animated: true, completion: nil)
    }

    func bluetoothCentralManagerDidDiscoverHost(_: BluetoothCentralManager, host: Host) {}
    
    func bluetoothCentralManagerDidConnectToHost(_: BluetoothCentralManager, users: [User]) {
        userCollectionViewController.dataSource = users
        userCollectionViewController.collectionView?.reloadData()
    }
    
    func bluetoothCentralManagerDidReceiveSuggestions(_: BluetoothCentralManager, suggestions: [Suggestion]) {
        suggestionCollectionViewController.dataSource = suggestions
        suggestionCollectionViewController.uniqueSuggestions = Set(suggestions)
        suggestionCollectionViewController.collectionView?.reloadData()
    }
    
    func bluetoothCentralManagerDidReceiveAddedSuggestion(_: BluetoothCentralManager, suggestion: Suggestion) {
        suggestionCollectionViewController.receivedAddedSuggestion(suggestion)
    }
    
    func bluetoothCentralManagerDidReceiveSuggestionIdsToRemove(_: BluetoothCentralManager, suggestionIds: [String]) {
        suggestionCollectionViewController.receivedSuggestionIdsToRemove(ids: suggestionIds)
    }
    
    func bluetoothCentralManagerDidStartVoting(_: BluetoothCentralManager) {
        performSegue(withIdentifier: Segues.StartVoting, sender: self)
    }
    
    func bluetoothCentralManagerDidReceiveHighestRatedSuggestion(_: BluetoothCentralManager, highestRatedSuggestion: Suggestion) {}
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
        guard let index = userCollectionViewController.dataSource.index(where: { (aUser) -> Bool in
            return aUser == user
        }) else {
            print("disconnected user's index not found")
            return
        }
        userCollectionViewController.dataSource.remove(at: index)
        userCollectionViewController.collectionView?.reloadData()
    }
    
    func bluetoothPeripheralManagerDidReceiveNewSuggestion(_: BluetoothPeripheralManager, suggestion: Suggestion) {
        suggestionCollectionViewController.receivedAddedSuggestion(suggestion)
    }
    
    func bluetoothPeripheralManagerDidReceiveSuggestionIdsToRemove(_: BluetoothPeripheralManager, suggestionIds: [String]) {
        suggestionCollectionViewController.receivedSuggestionIdsToRemove(ids: suggestionIds)
    }
    
    func bluetoothPeripheralManagerDidReceiveVotes(_: BluetoothPeripheralManager, votes: [Vote], from central: CBCentral) {}
}
