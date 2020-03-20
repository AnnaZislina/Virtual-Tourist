//
//  DownloadImage.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 06/11/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    
    func downloadImage(imageURL: String, completion: @escaping(UIImage?) -> Void) {
        guard let url = URL(string: imageURL) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            updateOnMainThread {
                self.image = image
            }
            completion(image)
        }
        task.resume()
    }
}

