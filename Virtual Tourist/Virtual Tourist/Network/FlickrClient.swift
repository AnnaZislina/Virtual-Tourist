//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 07/11/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import Foundation
import UIKit


class FlickrClient<Type: Codable> {
    
    func decode(data: Data, completion: @escaping(RestManager.Result<Type, Error>) -> Void) {
        do {
            let response = try JSONDecoder().decode(Type.self, from: data)
            completion(RestManager.Result.success(response))
        } catch let error {
            completion(RestManager.Result.failure(error))
        }
    }
}

enum Endpoint: String {
    case rest
    
    func getURL() -> (url: URL?, rest: RestManager?) {
        
        let rest = RestManager()
        rest.urlQueryParameters.add(value: "flickr.photos.search", forKey: "method")
        rest.urlQueryParameters.add(value: "aa4b76d44b82e4d6dd88ef73668361c4", forKey: "api_key")
        rest.urlQueryParameters.add(value: "json", forKey: "format")
        rest.urlQueryParameters.add(value: "1", forKey: "nojsoncallback")
        rest.urlQueryParameters.add(value: "30", forKey: "per_page")
        
        let url = URL(string: "https://www.flickr.com/services/\(self.rawValue)/")
        return(url, rest)
    }
}

struct FlickrURL {
    static func getFlickrImage(_ flickrModel: FlickrModel) -> String {
        return "https://farm\(flickrModel.farm).staticflickr.com/\(flickrModel.server)/\(flickrModel.id)_\(flickrModel.secret).jpg"
    }
}





