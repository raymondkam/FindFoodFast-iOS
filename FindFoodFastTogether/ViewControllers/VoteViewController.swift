//
//  VoteViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-12.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

class VoteViewController: UIViewController {
    
    var dataSource = [Suggestion]()
    var isHosting: Bool!

    fileprivate static let InitialCountdown: UInt = 5
    fileprivate let reuseIdentifier = "voteCell"
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

    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
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
                    guard let isHosting = self?.isHosting else {
                        print("don't know whether to send or receive results")
                        return
                    }
                    if isHosting {
                        self?.collectVotes()
                    } else {
                        self?.sendVotes()
                    }
                }
            }
        })
        
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    fileprivate func scrollToNextCell() {
        currentIndex += 1
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        countdown = VoteViewController.InitialCountdown
    }
    
    fileprivate func collectVotes() {
        // wait for clients to send votes
        print("collect votes")
        for suggestion in dataSource {
            print("rating for \(suggestion.name) is \(suggestion.rating)")
        }
    }
    
    fileprivate func sendVotes() {
        print("send votes")
        for suggestion in dataSource {
            print("rating for \(suggestion.name) is \(suggestion.rating)")
        }
    }
}

extension VoteViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VoteCollectionViewCell
        let suggestion = dataSource[indexPath.item]
        
        cell.title = suggestion.name
        cell.noImageTitle = suggestion.name
        cell.cosmoView.rating = Double(suggestion.rating)
        cell.cosmoView.didFinishTouchingCosmos = { [weak self] rating in
            guard let currentIndex = self?.currentIndex else {
                print("self is nil or has not current index")
                return
            }
            guard let dataSource = self?.dataSource else {
                print("self is nil or data source is nil")
                return
            }
            guard let isHosting = self?.isHosting else {
                print("self is nil or does not know whether is hosting")
                return
            }
            suggestion.rating = Int(rating)
            if currentIndex < dataSource.count - 1 {
                self?.scrollToNextCell()
            } else {
                if isHosting {
                    self?.collectVotes()
                } else {
                    self?.sendVotes()
                }
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
        return CGSize(width: view.frame.size.width - 20, height: 340)
    }
}
