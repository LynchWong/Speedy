//
//  Result.swift
//  Speedy
//
//  Created by Lynch Wong on 3/16/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation

public enum Result<Value, Error: ErrorType> {
    
    case Success(Value)
    case Failure(Error)
    
    public var isSuccess: Bool {
        switch self {
            case .Success:
                return true
            case .Failure:
                return false
        }
    }
    
    public var isFailure: Bool {
        return !isSuccess
    }
    
    public var value: Value? {
        switch self {
            case .Success(let value):
                return value
            case .Failure:
                return nil
        }
    }
    
    public var error: Error? {
        switch self {
            case .Success:
                return nil
            case .Failure(let error):
                return error
        }
    }
    
}

extension Result: CustomStringConvertible {
    
    public var description: String {
        switch self {
            case .Success:
                return "Success"
            case .Failure:
                return "Failure"
        }
    }
    
}

extension Result: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
            case .Success(let value):
                return "Success \(value)"
            case .Failure(let error):
                return "Failure \(error)"
        }
    }
    
}