//
//  FetchSecrets.swift
//  OnTheMap
//
//  Created by Georgi Markov on 10/21/21.
//

import Foundation

func fetchSecretsPlist() -> Dictionary<String, String> {
    guard let secretsFile = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
        fatalError("Could not find secrets file")
    }
    let url = URL(fileURLWithPath: secretsFile)
    let data = try! Data(contentsOf: url)
    guard let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [String:String] else {
        fatalError("Could not fetch information from plist:")
    }
    
    return plist
}
