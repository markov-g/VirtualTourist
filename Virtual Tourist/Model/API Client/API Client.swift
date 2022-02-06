//
//  API Client.swift
//  Virtual Tourist
//
//  Created by Georgi Markov on 12/29/21.
//

import Foundation
import OAuthSwift
import Alamofire

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
        case imageSearchSigned(lat: Double, long: Double)
        case imageSearchUnSigned(lat: Double, long: Double)
        
        static let base: String = "https://www.flickr.com/services/rest"
        
        var stringValue: String {
            switch self {
            case .imageSearchSigned(let lat, let long):
                return Endpoints.base + "?api_key=\(Constants.OAUTH_TOKEN)&method=\(Constants.FLICKR_SEARCH_METHOD)&per_page=\(Constants.NUM_OF_PHOTOS)&format=json&nojsoncallback=?&lat=\(lat)&lon=\(long)&page=1"
            case .imageSearchUnSigned(let lat, let long):
                return Endpoints.base + "?api_key=\(Constants.CONSUMER_KEY!)&method=\(Constants.FLICKR_SEARCH_METHOD)&per_page=\(Constants.NUM_OF_PHOTOS)&format=json&nojsoncallback=?&lat=\(lat)&lon=\(long)&page=1"
            }
        }
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
    }
    
   
    class func requestImagesForLocationUnsigned(latitude lat: Double, longitude long: Double, completion: @escaping([URL]?, Error?) -> Void) -> Void {
        let url = Endpoints.imageSearchUnSigned(lat: lat, long: long).url
        let task = URLSession.shared.dataTask(with: url) { data, response, err in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, err)
                }
                return
            }
            let decoder = JSONDecoder()
            var pictureURLs = [URL]()
            do {
                let responseObject = try decoder.decode(ImageRequestResponse.self, from: data)
                for photoURL in responseObject.photos.photo {
                    if let url = photoURL.download_url {
                        pictureURLs.append(url)
                    }
                }
                DispatchQueue.main.async {
                    completion(pictureURLs, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func requestImagesForLocation(latitude lat: Double, longitude long: Double, completion: @escaping([URL]?, Error?) -> Void) -> OAuthSwiftRequestHandle? {
        if let oauth = APIClient.oauth {
            oauth.client.get(Endpoints.imageSearchSigned(lat: lat, long: long).url, completionHandler: { result in
                switch result {
                case .success(let response):
                    let response_data = response.data
                    let decoder = JSONDecoder()
                    var pictureURLs = [URL]()
                    do {
                        let responseObject = try decoder.decode(ImageRequestResponse.self, from: response_data)
                        for photoURL in responseObject.photos.photo {
                            if let url = photoURL.download_url {
                                pictureURLs.append(url)
                            }
                        }
                        completion(pictureURLs, nil)
                    } catch {
                        completion(nil, error)
                    }
                case .failure(let error):
                    completion(nil, error)
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
            }
        } else {
            // TODO: notify user
            debugPrint("Consumer Key: \(Constants.CONSUMER_KEY) & Consumer Secret: \(Constants.CONSUMER_SECRET)")
        }
    }
}
