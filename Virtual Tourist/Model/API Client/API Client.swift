//
//  API Client.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 12/29/21.
//

import Foundation
import OAuthSwift

class APIClient {
    static var oauth: OAuth1Swift? = nil
    
    struct Constants {
        static let CONSUMER_KEY = fetchSecretsPlist()["FlickrKey"]
        static let CONSUMER_SECRET = fetchSecretsPlist()["FlickrSecret"]
        
        static let OAUTH_URL_BASE = "https://api.flickr.com/services"
        static let FLICKR_SEARCH_METHOD = "flickr.photos.search"
        static let OAUTH_URL_TOKEN_REQUEST_SUFFIX = "/oauth/request_token"
        static let OAUTH_URL_AUTHORIZATION_SUFFIX = "/oauth/authorize"
        static let OAUTH_URL_ACCESS_SUFFIX = "/oauth/access_token"
        
        static let IMAGE_BASE = "https://live.staticflickr.com"
        static let ACCURACY = 11 // city
        static let NUM_OF_PHOTOS = 30
        static var OAUTH_TOKEN: String? = nil
        static var OAUTH_TOKEN_SECRET: String? = nil
    }
    
    enum Endpoints {
        case imageSearch(lat: String, long: String)
        
        static let base: String = "https://www.flickr.com/services/rest"
        
        var stringValue: String {
            switch self {
            case .imageSearch(let lat, let long):
                return Endpoints.base + "?api_key=\(Constants.OAUTH_TOKEN!)&method=\(Constants.FLICKR_SEARCH_METHOD)&per_page=\(Constants.NUM_OF_PHOTOS)&format=json&nojsoncallback=?&lat=\(lat)&lon=\(long)&page=1"
            }
        }
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
    }
    
    class func requestImagesForLocation(latitude lat: String, longitude long: String) -> OAuthSwiftRequestHandle? {
        //TODO: construct flickr.images.search.url and search
        // St. Augustine: (lat: "29.901243", long: "81.312431")
        if let oauth = APIClient.oauth {
            oauth.client.get(Endpoints.imageSearch(lat: lat, long: long).url, completionHandler: { result in
                switch result {
                case .success(let response):
                    let response_data = response.data
                    print(String(data: response_data, encoding: .utf8))
                    let decoder = JSONDecoder()
                    do {
                        let responseObject = try decoder.decode(ImageRequestResponse.self, from: response_data)
                        for photo in responseObject.photos.photo{ print(photo.download_url) }
//                        DispatchQueue.main.async {
//                            completion(responseObject, nil)
//                        }
                    } catch {
                        print(error)
//                        DispatchQueue.main.async {
//                            completion(nil, error)
//                        }
                    }
                case .failure(let error):
                    print(error)
                }
            })
        }
        
        return nil
    }
    
    class func oauthorize() {
        if let key = Constants.CONSUMER_KEY,
           let secret = Constants.CONSUMER_SECRET {
            oauth = OAuth1Swift(consumerKey: key,
                                consumerSecret: secret,
                                requestTokenUrl: Constants.OAUTH_URL_BASE+Constants.OAUTH_URL_TOKEN_REQUEST_SUFFIX,
                                authorizeUrl: Constants.OAUTH_URL_BASE+Constants.OAUTH_URL_AUTHORIZATION_SUFFIX,
                                accessTokenUrl: Constants.OAUTH_URL_BASE+Constants.OAUTH_URL_ACCESS_SUFFIX)
            let handle = oauth!.authorize(withCallbackURL: "virtual-tourist://oauth-callback") { result in
                switch result {
                case .success(let (credential, response, parameters)):
                    Constants.OAUTH_TOKEN = credential.oauthToken
                    Constants.OAUTH_TOKEN_SECRET = credential.oauthTokenSecret
                    // Do your request
                case .failure(let error):
                    //TODO: inform user
                    print(error.localizedDescription)
                }
                // TODO: Testing
                requestImagesForLocation(latitude: "29.901243", longitude: "81.312431")
            }
        } else {
            // TODO: notify user
            debugPrint("Consumer Key: \(Constants.CONSUMER_KEY) & Consumer Secret: \(Constants.CONSUMER_SECRET)")
        }
    }
}
