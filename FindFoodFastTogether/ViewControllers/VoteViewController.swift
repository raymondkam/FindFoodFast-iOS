//
//  VoteViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-12.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class VoteViewController: UIViewController {
    
    var dataSource = [Suggestion]()
    var votes = [Vote]()
    var isHosting: Bool!

    fileprivate static let InitialCountdown: UInt = 5
    fileprivate let reuseIdentifier = "voteCell"
    fileprivate var totalRatingSuggestions = Set<Suggestion>()
    
    fileprivate var finalSuggestionIdToScore = [String: Int]()
    fileprivate var suggestionIdToSuggestion = [String: Suggestion]()
    
    fileprivate var userLocation: CLLocation?
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
        
        LocationManager.sharedInstance.requestLocation { [weak self] (location, error) in
            guard error == nil else {
                return
            }
            guard let location = location else {
                return
            }
            self?.userLocation = location
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
        
        // prepare for mapping back the suggestion id to suggestion later
        for suggestion in dataSource {
            suggestionIdToSuggestion.updateValue(suggestion, forKey: suggestion.id)
        }
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
        processRatingsFromVotes(votes: votes)
    }
    
    fileprivate func sendVotes() {
        print("send votes")
        BluetoothCentralManager.sharedInstance.sendHostVotes(votes: votes)
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
    
    fileprivate func processRatingsFromVotes(votes: [Vote]) {
        for vote in votes {
            let suggestionId = vote.suggestionId
            var score = vote.score
            if let currentScore = finalSuggestionIdToScore[suggestionId] {
                score += currentScore
            }
            finalSuggestionIdToScore.updateValue(score, forKey: suggestionId)
        }
        
        if pendingVotesFromCentrals.count == 0 && submittedHostVotes {
            // DONE COLLECTING
            print("done collecting all votes")
            findSuggestionWithHighestRating()
        }
    }
    
    fileprivate func findSuggestionWithHighestRating() {
        // put together all suggestion ids with the same score
        let scoresToSuggestionIds = finalSuggestionIdToScore.reduce([Int: [String]]()) { (scoreToSuggestionIds, suggestionIdToScore) -> [Int: [String]] in
            var scoreToSuggestionIds = scoreToSuggestionIds
            let suggestionId = suggestionIdToScore.key
            let score = suggestionIdToScore.value
            if var suggestionIdsWithSameScore = scoreToSuggestionIds[score] {
                suggestionIdsWithSameScore.append(suggestionId)
                scoreToSuggestionIds.updateValue(suggestionIdsWithSameScore, forKey: score)
            } else {
                scoreToSuggestionIds.updateValue([suggestionId], forKey: score)
            }
            return scoreToSuggestionIds
        }
        
        // find the highest score
        let highestScoringVote = scoresToSuggestionIds.max { (a, b) -> Bool in
            return a.key < b.key
        }
        
        if let highestScoringVote = highestScoringVote {
            let highestScore = highestScoringVote.key
            let highestScoringSuggestionIds = highestScoringVote.value
            
            let highestScoringSuggestionIndex: Int
            
            // randomly choose if there are more than 1
            if highestScoringSuggestionIds.count > 1 {
                print("randomly choosing one as there are multiple suggestions with the highest score")
                highestScoringSuggestionIndex = Int(arc4random_uniform(UInt32(highestScoringSuggestionIds.count)))
            } else {
                highestScoringSuggestionIndex = 0
            }
            
            let highestScoringSuggestionId = highestScoringSuggestionIds[highestScoringSuggestionIndex]
            let highestScoringSuggestion = suggestionIdToSuggestion[highestScoringSuggestionId]!
            highestScoringSuggestion.votes = highestScore
            print("best name: \(highestScoringSuggestion.name) and score: \(highestScore)")
            
            // notify the users that the highest rated suggestion was found
            BluetoothPeripheralManager.sharedInstance.sendHighestRatedSuggestion(highestRatedSuggestion: highestScoringSuggestion)

            showSuggestionWithHighestRating(highestRatedSuggestion: highestScoringSuggestion)
        } else {
            print("could not find highest rated suggestion")
        }
    }
    
    fileprivate func showSuggestionWithHighestRating(highestRatedSuggestion: Suggestion) {
        performSegue(withIdentifier: Segues.ShowHighestRatedSuggestion, sender: highestRatedSuggestion)
    }
}

extension VoteViewController: UICollectionViewDataSource {
    
    // MARK: Handle voting via CosmoView
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VoteCollectionViewCell
        let suggestion = dataSource[indexPath.item]
        
        cell.title = suggestion.name
        cell.subtitle = suggestion.type
        if let userLocation = userLocation {
            let suggestionLocation = CLLocation(latitude: suggestion.latitude, longitude: suggestion.longitude)
            let distance = suggestionLocation.distance(from: userLocation) / 1000
            cell.distance = String(format: "%.1f km", distance)
        }
        if let thumbnail = suggestion.thumbnail {
            cell.image = thumbnail
        }
        cell.cosmoView.rating = 0 // not voted yet, so should be 0
        
        // handle voting
        cell.cosmoView.didFinishTouchingCosmos = { [weak self] rating in
            guard let currentIndex = self?.currentIndex else {
                print("self is nil or has not current index")
                return
            }
            guard let dataSource = self?.dataSource else {
                print("self is nil or data source is nil")
                return
            }
            let vote = Vote(suggestionId: suggestion.id, score: Int(rating))
            self?.votes.append(vote)
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
        return CGSize(width: 337, height: 345)
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
    func bluetoothPeripheralManagerDidReceiveVotes(_: BluetoothPeripheralManager, votes: [Vote], from central: CBCentral) {
        // remove from pending set of centrals
        pendingVotesFromCentrals.remove(central)
        
        processRatingsFromVotes(votes: votes)
    }
    
    // Unused delegate methods
    func bluetoothPeripheralManagerDidBecomeReadyToAdvertise(_: BluetoothPeripheralManager) {}
    func bluetoothPeripheralManagerDidConnectWith(_: BluetoothPeripheralManager, newUser: User) {}
    func bluetoothPeripheralManagerDidDisconnectWith(_: BluetoothPeripheralManager, user: User) {}
    func bluetoothPeripheralManagerDidReceiveNewSuggestion(_: BluetoothPeripheralManager, suggestion: Suggestion) {}
    func bluetoothPeripheralManagerDidReceiveSuggestionIdsToRemove(_: BluetoothPeripheralManager, suggestionIds: [String]) {}
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
    func bluetoothCentralManagerDidReceiveAddedSuggestion(_: BluetoothCentralManager, suggestion: Suggestion) {}
    func bluetoothCentralManagerDidReceiveSuggestionIdsToRemove(_: BluetoothCentralManager, suggestionIds: [String]) {}
}
