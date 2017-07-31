//
//  PagedImageCollectionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-27.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit

protocol PagedImageCollectionViewControllerDelegate: class {
    func pagedImageCollectionViewControllerUpdatedNumberOfImages(numberOfImages: Int)
    func pagedImageCollectionViewControllerScrollToItem(item: Int)
}

class PagedImageCollectionViewController: UICollectionViewController {

    var dataSource = [UIImage]()
    var currentIndex = -1
    weak var delegate: PagedImageCollectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let result = scrollView.contentOffset.x / (scrollView.contentSize.width / CGFloat(dataSource.count))
        let isMoreThanHalfway = result.truncatingRemainder(dividingBy: 1) > 0.5
        let index = Int(result) + (isMoreThanHalfway ? 1 : 0)
        if currentIndex != index {
            currentIndex = index
            delegate?.pagedImageCollectionViewControllerScrollToItem(item: currentIndex)
        }
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        delegate?.pagedImageCollectionViewControllerUpdatedNumberOfImages(numberOfImages: dataSource.count)
        return dataSource.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imageReuseIdentifier, for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            imageCell.imageView.image = dataSource[indexPath.item]
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    

}

extension PagedImageCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.frame.size
    }
}
