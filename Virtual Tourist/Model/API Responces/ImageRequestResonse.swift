//
//  ImageRequestResonse.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 1/3/22.
//

import Foundation

struct ImageRequestResponse: Codable {
    let photos: Photos
    let stat: String
}
