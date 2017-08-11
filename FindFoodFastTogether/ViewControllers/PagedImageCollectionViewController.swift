//
//  PagedImageCollectionViewController.swift
//  FindFoodFastTogether
//
//  Created by Raymond Kam on 2017-07-27.
//  Copyright © 2017 Raymond Kam. All rights reserved.
//

import UIKit
import INSPhotoGallery

protocol PagedImageCollectionViewControllerDelegate: class {
    func pagedImageCollectionViewControllerUpdatedNumberOfImages(numberOfImages: Int)
    func pagedImageCollectionViewControllerScrollToItem(item: Int)
}

class PagedImageCollectionViewController: UICollectionViewController {

    var dataSource = [String]()
    var insPhotos: [INSPhoto]!
    var searchClient: SearchClient!
    var attributions = [NSAttributedString?]()
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
        return dataSource.count > 0 ? dataSource.count : 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imageReuseIdentifier, for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            
            if dataSource.count == 0 {
                imageCell.imageView.image = #imageLiteral(resourceName: "placeholderImage")
            } else {
                let widthString = String(Int(self.view.frame.size.width))
                let photoId = dataSource[indexPath.item]
                searchClient.fetchSuggestionPhoto(using: photoId, maxWidth: widthString, maxHeight: nil, completion: { (image, error) in
                    guard error == nil else {
                        print("error fetching suggestion image")
                        return
                    }
                    guard let image = image else {
                        print("suggestion image returned is nil")
                        return
                    }
                    UIView.transition(with: imageCell.imageView,
                                      duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        imageCell.imageView.image = image
                    },
                                      completion: nil)
                })
            }
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if dataSource.count == 0 {
            return
        }
        let cell = collectionView.cellForItem(at: indexPath)
        let galleryViewController = INSPhotosViewController(photos: insPhotos, initialPhoto: insPhotos[indexPath.item], referenceView: cell)
        galleryViewController.navigateToPhotoHandler = { [weak self] photo in
            guard let insPhoto = photo as? INSPhoto else {
                print("not an ins photo")
                return
            }
            if let index = self?.insPhotos.index(of: insPhoto) {
                let indexPath = IndexPath(item: index, section: 0)
                collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            }
        }
        galleryViewController.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
            guard let insPhoto = photo as? INSPhoto else {
                print("not an ins photo")
                return nil
            }
            if let index = self?.insPhotos.index(of: insPhoto) {
                let indexPath = IndexPath(item: index, section: 0)
                return collectionView.cellForItem(at: indexPath)
            }
            return nil
        }
        
        present(galleryViewController, animated: true, completion: nil)
    }
}

extension PagedImageCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.view.frame.size
    }
}
