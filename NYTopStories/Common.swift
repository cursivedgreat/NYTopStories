//
//  Common.swift
//  NYTopStories
//
//  Created by Avinash on 09/07/2019.
//  Copyright © 2019 Avinash. All rights reserved.
//

import Foundation

let DB_NAME = "appdb.db"
let APP_FOLDER = ".app"
let APP_LAUNCHED_BEFORE = "com.Avinash.Test.NyTopStories.AppLaunchedBefore"

/// All the expected Section implemented in the app from New York Times
///
/// - home: default section
/// - science:
/// - technology:
/// - business:
/// - world:
/// - movies:
/// - travel:
enum AllowedSectionType: String, CaseIterable {
    case home
    case science
    case technology
    case business
    case world
    case movies
    case travel
}


/// Api to get app folderr
///
/// - Returns: App Folder url
func documentURL() -> URL? {
    let fileManager = FileManager.default
    if let tDocumentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
        let filePath =  tDocumentDirectory.appendingPathComponent("\(APP_FOLDER)")
        if !fileManager.fileExists(atPath: filePath.path) {
            do {
                try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Couldn't create document directory")
            }
        }
        NSLog("Document directory is \(filePath)")
        return filePath
    } else {
        return nil
    }
}

/// Method to copy Bundle Database to app folder.
///
/// - Throws: Propagates the error if any.
func replaceDb() throws {
    if let newDBUrl = documentURL()?.appendingPathComponent("\(DB_NAME)", isDirectory: false),
        let bundledDbURL = Bundle.main.resourceURL?.appendingPathComponent("\(DB_NAME)") {
//        print("DB path: \(newDBUrl.absoluteString)")
//        print("Bundle path: \(bundledDbURL.absoluteString)")
        try FileManager.default.copyItem(at: bundledDbURL, to: newDBUrl)
    }
}
