//
//  Response.swift
//  Speedy
//
//  Created by Lynch Wong on 3/16/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation

public struct Response<Value, Error: ErrorType> {
    
    public let request: NSURLRequest?
    
    public let response: NSHTTPURLResponse?
    
    public let data: NSData?
    
    public let result: Result<Value, Error>
    
    public init(request: NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, result: Result<Value, Error>) {
        self.request = request
        self.response = response
        self.data = data
        self.result = result
    }
    
}