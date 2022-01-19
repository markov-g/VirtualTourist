//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 1/3/22.
//

import Foundation

struct Photos: Codable {
    let page: Int
    let pages: Int
    let per_page: Int
    let total: Int
    let photo: [Photo]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case per_page = "perpage"
        case total
        case photo
    }
}

struct Photo: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    
    var download_url: URL? {
        // https://live.staticflickr.com/{server-id}/{id}_{secret}_{size-suffix}.jpg
        let url = APIClient.Constants.IMAGE_BASE + "/\(server)/\(id)_\(secret).jpg"
        return URL(string: url) ?? nil
    }
}
