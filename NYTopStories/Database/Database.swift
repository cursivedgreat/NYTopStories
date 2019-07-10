//
//  Database.swift
//  NYTopStories
//
//  Created by Avinash on 09/07/2019.
//  Copyright © 2019 Avinash. All rights reserved.
//

import Foundation
import SQLite3



/// Possible error that may occur in database operation
///
/// - openDatabase: Error while opening database
/// - prepare: Error while compiling statement
/// - step: Error while executing compiled statement
/// - bind: Error while binding values to compiled SQLstatement
enum SQLiteError: Error {
    case openDatabase(message: String)
    case prepare(message: String)
    case step(message: String)
    case bind(message: String)
}

/// Protocol, a class that represent a Table in the database, must adhere to.
protocol SQLTable {
    static var insertStatement: String { get }
    static var deleteStatement: String { get }
    static var getTableStatement: String { get }
}

/// Struct to represent database table.
struct Response {
    var apiResponse: ApiResponse
}

extension Response: SQLTable {
    static var insertStatement: String {
        return  """
        INSERT INTO ApiResponse (status, copyright, section, last_updated, num_results, results) VALUES (?, ?, ?, ?, ?, ?);
        """
    }
    
    static var deleteStatement: String {
        return """
            DELETE FROM ApiResponse;
        """
    }
    
    static var  getTableStatement: String {
        return """
            SELECT * FROM ApiResponse;
        """
    }
}

/// The only class to manage database.
class SQLiteDatabase {
    fileprivate let dbPointer: OpaquePointer?
    fileprivate init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    /// Convenience Database initializer.
    ///
    /// - Parameter dbPath: Path to db
    /// - Returns: Database instance (Class that manages db)
    /// - Throws: Propagates the error to caller if any.
    static func open(path dbPath: String) throws -> SQLiteDatabase {
        var db: OpaquePointer? = nil
        
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("DB path is \(dbPath)")
            return SQLiteDatabase(dbPointer: db)
        } else {
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String.init(cString: errorPointer)
                throw SQLiteError.openDatabase(message: message)
            } else {
                throw SQLiteError.openDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
    
    /// Abstact method the deduce error message
    fileprivate var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    /// Public Database api to persist response.
    ///
    /// - Parameter aResponse: Current ApiResponse.
    /// - Throws: Propagates the error if any.
    func save(response aResponse: ApiResponse) throws {
        try clean(table: Response.self)
        try insert(response: Response(apiResponse: aResponse))
    }
    
    deinit {
        //Closes the database upon deallocating the class
        sqlite3_close(dbPointer)
    }
}

extension SQLiteDatabase {
    /// Api to compile the sql to be executed.
    ///
    /// - Parameter sqlString: SQL statement
    /// - Returns: Swift type pointer to compiled statement.
    /// - Throws: Propagates the error if any.
    private func prepareStatement(sql sqlString: String) throws -> OpaquePointer? {
        var statement: OpaquePointer? = nil
        guard sqlite3_prepare_v2(dbPointer, sqlString, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.prepare(message: errorMessage)
        }
        return statement
    }
}

extension SQLiteDatabase {
    /// Database api to persist the Decoded Response.
    ///
    /// - Parameter aResponse: Decoded Response object to be persisted.
    /// - Throws: Propagates the error if any.
    private func insert(response aResponse: Response) throws {
        let insertStatement = try prepareStatement(sql: Response.insertStatement)
        defer {
            sqlite3_finalize(insertStatement)
        }
        
        let status = (aResponse.apiResponse.status ?? "") as NSString
        let copyright = (aResponse.apiResponse.copyright ?? "") as NSString
        let section = (aResponse.apiResponse.section ?? "") as NSString
        let lastUpdated = (aResponse.apiResponse.last_updated ?? "") as NSString
        let numResults = Int32(aResponse.apiResponse.num_results ?? -1)
        let results = aResponse.apiResponse.results ?? []
        let resultsData = try JSONEncoder().encode(results)
        let resultString = (String(data: resultsData, encoding: .utf8) ?? "[]") as NSString
        
        guard
            sqlite3_bind_text(insertStatement, 1, status.utf8String, -1, nil) == SQLITE_OK &&
                sqlite3_bind_text(insertStatement, 2, copyright.utf8String, -1, nil) == SQLITE_OK &&
                sqlite3_bind_text(insertStatement, 3, section.utf8String, -1, nil) == SQLITE_OK &&
                sqlite3_bind_text(insertStatement, 4, lastUpdated.utf8String, -1, nil) == SQLITE_OK &&
                sqlite3_bind_int(insertStatement, 5, numResults) == SQLITE_OK &&
                sqlite3_bind_text(insertStatement, 6, resultString.utf8String, -1, nil) == SQLITE_OK
            else {
                throw SQLiteError.bind(message: errorMessage)
        }
        
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.step(message: errorMessage)
        }
        
        print("Successfully inserted row")
    }
}

extension SQLiteDatabase {
    /// Database api to retrieve cached ressponse.
    ///
    /// - Returns: Decoded Response from table.
    /// - Throws: Propagates the error if any.
    private func query() throws -> ApiResponse {
        var response = ApiResponse()
        let queryStatement = try prepareStatement(sql: Response.getTableStatement)
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        if sqlite3_step(queryStatement) == SQLITE_ROW {
            response.status = String(cString: sqlite3_column_text(queryStatement, 0))
            response.copyright = String(cString: sqlite3_column_text(queryStatement, 1))
            response.section = String(cString: sqlite3_column_text(queryStatement, 2))
            response.last_updated = String(cString: sqlite3_column_text(queryStatement, 3))
            response.num_results = Int(sqlite3_column_int(queryStatement, 4))
            let resultString = String(cString: sqlite3_column_text(queryStatement, 5))
            if let resultData = resultString.data(using: .utf8) {
               response.results = try JSONDecoder().decode([Results].self, from: resultData)
            }
        }
        return response
    }
}


extension SQLiteDatabase {
    /// Database api to clear the only table
    ///
    /// - Parameter aTable: Table name
    /// - Throws: Propagate the errors if any.
    private func clean(table aTable: SQLTable.Type) throws {
        let cleanTableStatement = try prepareStatement(sql: aTable.deleteStatement)
        
        defer {
            sqlite3_finalize(cleanTableStatement)
        }
        
        guard sqlite3_step(cleanTableStatement) == SQLITE_DONE else {
            throw SQLiteError.step(message: errorMessage)
        }
    }
}
