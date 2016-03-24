//
//  Encoding.swift
//  Speedy
//
//  Created by Lynch Wong on 3/15/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation

/**
 HTTP 方法
 
 https://tools.ietf.org/html/rfc7231#section-4.3
 */
public enum Method: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

public enum ParameterEncoding {
    case URL
    case EncodingInURL
    case JSON
    case PropertyList(NSPropertyListFormat, NSPropertyListWriteOptions)
    case Custom((NSURLRequest, [String: AnyObject]?) -> NSMutableURLRequest)
    
    public func encode(urlRequest: NSURLRequest, parameters: [String: AnyObject]?) throws -> NSMutableURLRequest {
        var mutableRequest = urlRequest.mutableCopy() as! NSMutableURLRequest
        
        guard let parameters = parameters else {
            return mutableRequest
        }
        
        switch self {
            case .URL:
                if let method = Method(rawValue: mutableRequest.HTTPMethod) {
                    switch method {
                        case .GET, .HEAD, .DELETE:
                            mutableRequest = encodesParametersInURL(mutableRequest, parameters: parameters)
                        default:
                            if mutableRequest.valueForHTTPHeaderField("Content-Type") == nil {
                                mutableRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
                            }
                            mutableRequest.HTTPBody = queryString(parameters).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                    }
                }
            case .EncodingInURL:
                mutableRequest = encodesParametersInURL(mutableRequest, parameters: parameters)
            case .JSON:
                let data = try NSJSONSerialization.dataWithJSONObject(parameters, options: NSJSONWritingOptions())
            
                if mutableRequest.valueForHTTPHeaderField("Content-Type") == nil {
                    mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            
                mutableRequest.HTTPBody = data
            case .PropertyList(let format, let options):
                let data = try NSPropertyListSerialization.dataWithPropertyList(parameters, format: format, options: options)
                
                if mutableRequest.valueForHTTPHeaderField("Content-Type") == nil {
                    mutableRequest.setValue("application/x-plist", forHTTPHeaderField: "Content-Type")
                }
                
                mutableRequest.HTTPBody = data
            case .Custom(let closure):
                mutableRequest = closure(mutableRequest, parameters)
        }
        
        return mutableRequest
    }
    
    /**
     将参数拼接在请求的URL后面
     
     - parameter mutableRequest: 用于请求的 NSMutableURLRequest
     - parameter parameters:     参数字典
     
     - returns: 返回请求
     */
    public func encodesParametersInURL(mutableRequest: NSMutableURLRequest, parameters: [String: AnyObject]) -> NSMutableURLRequest {
        if let components = NSURLComponents(URL: mutableRequest.URL!, resolvingAgainstBaseURL: false) where !parameters.isEmpty {
            let percentEncodedQuery = (components.percentEncodedQuery.map({ $0 + "&" }) ?? "") + queryString(parameters)
            components.percentEncodedQuery = percentEncodedQuery
            mutableRequest.URL = components.URL
        }
        return mutableRequest
    }
    
    /**
     拼接参数
     
     - parameter parameter: 参数字典
     
     - returns:
     */
    public func queryString(parameters: [String: AnyObject]) -> String {
        let elements = query(parameters)
        return (elements.map({ "\($0)=\($1)" }) as [String]).joinWithSeparator("&")
    }
    
    public func query(parameters: [String: AnyObject]) -> [(String, String)] {
        var elements: [(String, String)] = []
        
        for (key, value) in parameters {
            elements += queryElement(key, value: value)
        }
        
        return elements
    }
    
    public func queryElement(key: String, value: AnyObject) -> [(String, String)] {
        var elements: [(String, String)] = []
        
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                elements += queryElement("\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                elements += queryElement("\(key)[]", value: value)
            }
        } else {
            elements.append((percentEscapes(key), percentEscapes("\(value)")))
        }
        
        return elements
    }
    
    /**
     URL编码，百分号编码。
     
     - parameter string: 要编码的字符串
     
     - returns: 编码后的字符串
     */
    public func percentEscapes(string: String) -> String {
        //原始字符串
        let originalString = string as CFStringRef
        //需要编码的字符
        let legalURLCharactersToBeEscaped = ":/?#[]@!$&'()*+,;=" as CFStringRef
        let escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                   originalString,
                                                                   nil,
                                                                   legalURLCharactersToBeEscaped,
                                                                   CFStringBuiltInEncodings.UTF8.rawValue)
        return escapedString as String
    }
}