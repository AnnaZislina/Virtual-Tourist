//
//  CollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 06/11/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imageNotAvailable = UIImage(named: "noImage")
    
       override func prepareForReuse() {
           imageView.image = nil
       }
    
    var photo: Photo? {
        didSet {
            if let photo = photo, let url = photo.url {
                self.imageView.image = imageNotAvailable
                guard let data = photo.data else {
                    imageView.downloadImage(imageURL: url, completion: { data in
                        if let data = data {
                            photo.data = data.jpegData(compressionQuality: 1)
                            do {
                                try photo.managedObjectContext?.save()
                            } catch {
                                updateOnMainThread {
                                    self.imageView.image = self.imageNotAvailable
                                }
                            }
                        }
                    })
                    return
                }
                imageView.image = UIImage(data: data)
            }
        }
    }
}

