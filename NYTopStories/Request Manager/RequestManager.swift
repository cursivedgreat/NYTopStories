//
//  RequestManager.swift
//  NYTopStories
//
//  Created by Avinash on 08/07/2019.
//  Copyright © 2019 Avinash. All rights reserved.
//

import Foundation
import UIKit

enum HttpMethodType: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case copy = "COPY"
    case head = "HEAD"
    case options = "OPTIONS"
}

enum RequestServerType: String {
    case staging
    case preProd
    case prod
}

enum ApiError: Error {
    case unknwon
    case httpError
    case clientError
    case serverError
    case invalidSection
    case parseError
    case invalidURLComponent
    case dbMissing
    case noCacheFound
}

/// Class to manage all network requests.
class RequestManager {
    public static let shared = RequestManager()
    var sharedSession: MRURLSession = URLSession.shared
    
    private let apiKey = "1KlWLU5wyaHaUvZV8z5VxnuuPLqABzmP"
    private let baseUrl = "https://api.nytimes.com/svc/topstories/v2/"
    private let CACHE_POLICY = NSURLRequest.CachePolicy.useProtocolCachePolicy
    private let TIME_OUT_INTERVAL: TimeInterval = 60
    
//    private let standardParams: [String: Any] = [
//        "utc_seconds": TimeZone.current.secondsFromGMT(),
//        "application_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!,
//        "build_number": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!,
//        "os_version": UIDevice.current.systemVersion,
//        "device_model": UIDevice.current.model,
//        "app": Bundle.main.bundleIdentifier!,
//        "os_type":1
//    ]

    /// Variable to keep track of number of ongoing network request.
    static var requestCounter = 0 {
        didSet {
            updateActivityIndicator()
        }
    }
    
    /// Single network call to get user selected section response.
    ///
    /// - Parameters:
    ///   - section: default 'home' or user selected section from NewYork Times
    ///   - method: Http Method
    ///   - aCompletion: Callback closure with Result carrying either Data or Error.
    public func request(forSection section: String,
                        withHttpMethod method: HttpMethodType,
                        withCompletion aCompletion: @escaping (_ result: Result<Data, ApiError>) -> Void)
    {
        let urlString = "\(baseUrl)\(section).json"
        guard let url = URL(string: urlString)
            else {
                return  aCompletion(.failure(.invalidSection))
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryParams = [URLQueryItem(name: "api-key", value: apiKey)]
//        queryParams
//            .append(contentsOf: standardParams.map {
//                 URLQueryItem(name: $0.key, value: "\($0.value)")
//            })
        components?.queryItems = queryParams
        guard let requestURL = components?.url
            else {
                return aCompletion(.failure(.invalidURLComponent))
        }
        
        var request = URLRequest(url: requestURL, cachePolicy: CACHE_POLICY, timeoutInterval: TIME_OUT_INTERVAL)
        request.httpMethod = method.rawValue
        
        RequestManager.requestCounter += 1
        sharedSession.dataTask(with: request) { (data, urlResponse, error) in
            print("Error is \(error.debugDescription)")
            RequestManager.requestCounter -= 1
            guard let httpResponse = urlResponse as? HTTPURLResponse
                else {
                    return aCompletion(.failure(.unknwon))
            }
            if 200 ..< 300 ~= httpResponse.statusCode,
                let data = data {
                 aCompletion(.success(data))
            }
            else if 400 ..< 500 ~= httpResponse.statusCode {
                aCompletion(.failure(.clientError))
            }
            else {
                 aCompletion(.failure(.serverError))
            }
        }.resume()
        
    }
    
    /// Method to indicate an ongoing network request
    static func updateActivityIndicator() {
        DispatchQueue.main.async {
            if requestCounter == 0 {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            } else {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
    }
    
}
