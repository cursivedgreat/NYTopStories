//
//  ViewModel.swift
//  NYTopStories
//
//  Created by Avinash on 09/07/2019.
//  Copyright © 2019 Avinash. All rights reserved.
//

import Foundation

class ViewModel {
    var selectedSection = AllowedSectionType.home.rawValue
    
    /// Actual Api to get either default `home` section or user selected section.
    ///
    /// - Parameter aCompletion: Completion block callback with Result containing with Response or error.
    func refreshSection(withCompletion aCompletion: @escaping (_ response: Result<ApiResponse, ApiError>) -> Void) {
        RequestManager.shared.request(forSection: selectedSection, withHttpMethod: .get) { result in
            switch result {
            case .success(let data):
                print("success")
                do {
                    let response = try JSONDecoder().decode(ApiResponse.self, from: data)
                    aCompletion(.success(response))
                    self.cache(theResponse: response)
                    UserDefaults.standard.set(true, forKey: APP_LAUNCHED_BEFORE)
                    UserDefaults.standard.synchronize()
                } catch {
                    print("Parse error: \(error.localizedDescription)")
                    aCompletion(.failure(.parseError))
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                aCompletion(.failure(error))
            }
        }
    }
    
    
    /// Retrieves the cached response from Database
    ///
    /// - Parameter aCompletion: Completion block with Result containing either result or error
    /// - Throws: propagates the error occurs while in process
    func loadCachedResponse(withCompletion aCompletion: @escaping (_ response: Result<ApiResponse, ApiError>) -> Void) throws {
        if let dbURL = documentURL()?.appendingPathComponent(DB_NAME) {
            let response = try SQLiteDatabase
                .open(path: dbURL.absoluteString)
                .query()
            self.selectedSection = response.section ?? AllowedSectionType.home.rawValue
            aCompletion(.success(response))
        } else {
            aCompletion(.failure(.dbMissing))
        }
    }
    
    /// Structures the decoded response in the required format
    ///
    /// - Parameter response: Api Response from server or Cached
    /// - Returns: Structured Sections
    func format(apiResponse response: ApiResponse) -> [[String: [Results]]]{
        let intialVal = [String: [Results]]()
        let tResult =  response
            .results?
            .compactMap { $0 }
            .reduce(intialVal) { ( dict, tuple) in
                var nextDict = dict
                if let sectionName = tuple.section {
                    if let _ = nextDict[sectionName] {
                        nextDict[sectionName]?.append(tuple)
                    } else {
                        nextDict[sectionName] = [tuple]
                    }
                }
                return nextDict
            } ?? [:]
        return Array(tResult.map { [$0.key: $0.value] })
    }
    
    
    /// Initiates the selected section response in the database
    /// and handles error if any
    /// - Parameter response: Decoded response
    private func cache(theResponse response: ApiResponse) {
        do {
           try self.save(response: response)
        } catch {
            print("Couldn't cache the response. Error: \(error)")
        }
    }
    
    
    /// Checks if Database is present in app folder else gets a copy of it from Bundle
    /// and initiates response persiting process
    /// - Parameter aResponse: Decoded response
    /// - Throws: Propagates the error that may occurs
    private func save(response aResponse: ApiResponse) throws {
        if let dbURL = documentURL()?.appendingPathComponent(DB_NAME) {
            if !FileManager.default.fileExists(atPath: dbURL.path) {
                try replaceDb()
            }
            try SQLiteDatabase
                .open(path: dbURL.absoluteString)
                .save(response: aResponse)
        }
    }
}

struct ApiResponse: Codable {
    var status: String?
    var copyright: String?
    var section: String?
    var last_updated: String?
    var num_results: Int?
    var results: [Results]?
}

struct Results: Codable {
    var section: String?
    var title: String?
    var abstract: String?
    var url: URL?
    var byline: String?
    var updated_date: String?
    var created_date: String?
    var published_date: String?
    var multimedia: [Multimedia]?
    
    
    /// Get the formatted date string from `published_date`
    ///
    /// - Returns: Formatted Date String from `published_date` key
    func getPublishedDate() -> String? {
        if let tDate = published_date {
            var publishedDate = Date()
            var dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            publishedDate = dateFormatter.date(from: tDate)!
            dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            return dateFormatter.string(from: publishedDate)
        }
        return nil
    }
}

struct Multimedia: Codable {
    var url: URL?
    var format: String?
    var caption: String?
    var copyright: String?
}
