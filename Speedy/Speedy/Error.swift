//
//  Error.swift
//  Speedy
//
//  Created by Lynch Wong on 3/18/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation

public struct Error {

    public static let Domain = "com.speedy.error"
    
    public enum Code: Int {
        case InputStreamReadFailed           = -8000
        case OutputStreamWriteFailed         = -8001
        case ContentTypeValidationFailed     = -8002
        case StatusCodeValidationFailed      = -8003
        case DataSerializationFailed         = -8004
        case StringSerializationFailed       = -8005
        case JSONSerializationFailed         = -8006
        case PropertyListSerializationFailed = -8007
    }
    
    public static func errorWithCode(code: Code, failureReason: String) -> NSError {
        return errorWithCode(code.rawValue, failureReason: failureReason)
    }
    
    public static func errorWithCode(code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey: failureReason]
        return NSError(domain: Domain, code: code, userInfo: userInfo)
    }
    
}