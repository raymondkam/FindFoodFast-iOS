//
//  VoteViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-12.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreBluetooth

class VoteViewController: UIViewController {
    
    var dataSource = [Suggestion]()
    var isHosting: Bool!

    fileprivate static let InitialCountdown: UInt = 5
    fileprivate let reuseIdentifier = "voteCell"
    fileprivate var totalRatingSuggestions = Set<Suggestion>()
    fileprivate var pendingVotesFromCentrals: Set<CBCentral>!
    fileprivate var submittedHostVotes = false
    fileprivate var timer: Timer!
    fileprivate var currentIndex = 0
    fileprivate var countdown: UInt {
        get {
            guard let text = countdownLabel.text else {
                return UInt.max
            }
            guard let countdown = UInt(text) else {
                return UInt.max
            }
            return countdown
        }
        set(newCountdown) {
            DispatchQueue.main.async {
                self.countdownLabel.text = String(newCountdown)
            }
        }
    }
    
    @IBOutlet weak var votesProcessingView: UIStackView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if isHosting {
            // note down the centrals we will need to collect votes from later
            pendingVotesFromCentrals = Set(BluetoothPeripheralManager.sharedInstance.subscribedCentrals)
        }
        
        // hide the nav bar for the voting process until done
        navigationItem.backBarButtonItem?.title = "Done"
        navigationController?.isNavigationBarHidden = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            guard var countdown = self?.countdown else {
                return
            }
            if countdown > 0 {
                countdown -= 1
                self?.countdown = countdown
            } else {
                guard let currentIndex = self?.currentIndex else {
                    print("vote vc: current index or self is nil")
                    return
                }
                guard let dataSource = self?.dataSource else {
                    print("vote vc: data source or self is nil")
                    return
                }
                if currentIndex < dataSource.count - 1 {
                    self?.scrollToNextCell()
                } else {
                    // end timer and submit results
                    timer.invalidate()
                    self?.doneVoting()
                }
            }
        })
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifer = segue.identifier else {
            print("segue not identified")
            return
        }
        if segueIdentifer == Segues.ShowHighestRatedSuggestion {
            guard let highestRatedSuggestion = sender as? Suggestion else {
                print("passed parameter to segue is not a suggestion")
                return
            }
            guard let highestRatedSuggestionViewController = segue.destination as? HighestRatedSuggestionViewController else {
                print("error destination not highest rated suggestion view controller")
                return
            }
            highestRatedSuggestionViewController.highestRatedSuggestion = highestRatedSuggestion
            highestRatedSuggestionViewController.isHosting = isHosting
        }
    }

    fileprivate func scrollToNextCell() {
        currentIndex += 1
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        countdown = VoteViewController.InitialCountdown
    }
    
    fileprivate func collectVotes() {
        // save your own votes
        submittedHostVotes = true
        processRatingsFromVotedSuggestions(votedSuggestions: dataSource)
    }
    
    fileprivate func sendVotes() {
        print("send votes")
        for suggestion in dataSource {
            print("rating for \(suggestion.name) is \(suggestion.voteRating)")
        }
        
        BluetoothCentralManager.sharedInstance.sendHostVotedSuggestions(votedSuggestions: dataSource)
    }
    
    fileprivate func doneVoting() {
        UIView.animate(withDuration: 0.6, animations: { 
            self.collectionView.alpha = 0
            self.countdownLabel.alpha = 0
            self.votesProcessingView.alpha = 1
        }) { (finished) in
            if finished {
                self.collectionView.isHidden = true
                self.countdownLabel.isHidden = true
            }
        }
        
        if isHosting {
            self.collectVotes()
        } else {
            self.sendVotes()
        }
    }
    
    fileprivate func processRatingsFromVotedSuggestions(votedSuggestions: [Suggestion]) {
        for votedSuggestion in votedSuggestions {
            if let totalRatingSuggestion = totalRatingSuggestions.first(where: { (suggestion) -> Bool in
                return votedSuggestion == suggestion
            }) {
                totalRatingSuggestion.voteRating += votedSuggestion.voteRating
                totalRatingSuggestions.update(with: totalRatingSuggestion)
            } else {
                // not in the set of suggestions
                totalRatingSuggestions.insert(votedSuggestion)
            }
        }
        
        if pendingVotesFromCentrals.count == 0 && submittedHostVotes {
            // DONE COLLECTING
            print("done collecting all votes")
            findSuggestionWithHighestRating()
        }
    }
    
    fileprivate func findSuggestionWithHighestRating() {
        let highestRatedSuggestion = totalRatingSuggestions.max { (a, b) -> Bool in
            return a.voteRating < b.voteRating
        }
        
        if let highestRatedSuggestion = highestRatedSuggestion {
            print("best name: \(highestRatedSuggestion.name) and rating: \(highestRatedSuggestion.voteRating)")
            
            BluetoothPeripheralManager.sharedInstance.sendHighestRatedSuggestion(highestRatedSuggestion: highestRatedSuggestion)
            
            showSuggestionWithHighestRating(highestRatedSuggestion: highestRatedSuggestion)
        } else {
            print("error, could not find highest rated suggestion")
        }
    }
    
    fileprivate func showSuggestionWithHighestRating(highestRatedSuggestion: Suggestion) {
        performSegue(withIdentifier: Segues.ShowHighestRatedSuggestion, sender: highestRatedSuggestion)
    }
}

extension VoteViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VoteCollectionViewCell
        let suggestion = dataSource[indexPath.item]
        
        cell.title = suggestion.name
        cell.noImageTitle = suggestion.name
        cell.cosmoView.rating = Double(suggestion.voteRating)
        cell.cosmoView.didFinishTouchingCosmos = { [weak self] rating in
            guard let currentIndex = self?.currentIndex else {
                print("self is nil or has not current index")
                return
            }
            guard let dataSource = self?.dataSource else {
                print("self is nil or data source is nil")
                return
            }
            suggestion.voteRating = Int(rating)
            if currentIndex < dataSource.count - 1 {
                self?.scrollToNextCell()
            } else {
                self?.timer.invalidate()
                self?.doneVoting()
            }
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
}

extension VoteViewController: UICollectionViewDelegate {
    
}

extension VoteViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 337, height: 340)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return (self.view.frame.size.width - 337) / 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return (self.view.frame.size.width - 337) / 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let inset = (self.view.frame.size.width - 337) / 2
        return UIEdgeInsetsMake(0, inset, 0, inset)
    }
}

extension VoteViewController: BluetoothPeripheralManagerDelegate {
    func bluetoothPeripheralManagerDidReceiveVotedSuggestions(_: BluetoothPeripheralManager, votedSuggestions: [Suggestion], from central: CBCentral) {
        // remove from pending set of centrals
        pendingVotesFromCentrals.remove(central)
        
        processRatingsFromVotedSuggestions(votedSuggestions: votedSuggestions)
    }
    
    // Unused delegate methods
    func bluetoothPeripheralManagerDidBecomeReadyToAdvertise(_: BluetoothPeripheralManager) {}
    func bluetoothPeripheralManagerDidConnectWith(_: BluetoothPeripheralManager, newUser: User) {}
    func bluetoothPeripheralManagerDidDisconnectWith(_: BluetoothPeripheralManager, user: User) {}
    func bluetoothPeripheralManagerDidReceiveNewSuggestion(_: BluetoothPeripheralManager, suggestion: Suggestion) {}
}

extension VoteViewController: BluetoothCentralManagerDelegate {
    func bluetoothCentralManagerDidReceiveHighestRatedSuggestion(_: BluetoothCentralManager, highestRatedSuggestion: Suggestion) {
        performSegue(withIdentifier: Segues.ShowHighestRatedSuggestion, sender: highestRatedSuggestion)
    }
    
    // Unused delegate methods
    func bluetoothCentralManagerDidStartVoting(_: BluetoothCentralManager) {}
    func bluetoothCentralManagerDidDiscoverHost(_: BluetoothCentralManager, host: Host) {}
    func bluetoothCentralManagerDidConnectToHost(_: BluetoothCentralManager, users: [User]) {}
    func bluetoothCentralManagerDidReceiveSuggestions(_: BluetoothCentralManager, suggestions: [Suggestion]) {}
}
