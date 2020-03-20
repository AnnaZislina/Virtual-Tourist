//
//  FlickrModel.swift
//  Virtual Tourist
//
//  Created by Anna Zislina on 07/11/2019.
//  Copyright © 2019 Anna Zislina. All rights reserved.
//

import Foundation

struct FlickrModel: Codable {
    let id: String
    let owner: String
    let server: String
    let secret: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
}

struct FlickrImages: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [FlickrModel]
}

struct FlickrStat: Codable {
    let photos: FlickrImages
    let stat: String
}

