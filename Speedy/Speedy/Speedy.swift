//
//  Speedy.swift
//  Speedy
//
//  Created by Lynch Wong on 3/14/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation

public class Speedy {
    
    // MARK: - Request
    
    public class func request(
        httpMethod: Method,
        _ urlString: String,
        parameters: [String: AnyObject]? = nil,
        encoding: ParameterEncoding? = .URL,
        headers: [String: String]? = nil)
        -> Request
    {
        return Manager.sharedInstance.request(
            httpMethod,
            urlString: urlString,
            parameters: parameters,
            encoding: encoding,
            headers: headers
        )
    }
    
    public class func request(request: NSURLRequest) -> Request {
        return Manager.sharedInstance.request(request)
    }
    
    // MARK: - Upload
    
    public class func upload(
        httpMethod: Method,
        _ urlString: String,
        headers: [String: String]? = nil,
        file: NSURL)
        -> Request
    {
        return Manager.sharedInstance.upload(
            httpMethod,
            urlString,
            headers: headers,
            file: file
        )
    }
    
    public class func upload(request: NSURLRequest, file: NSURL) -> Request {
        return Manager.sharedInstance.upload(request, file: file)
    }
    
    public class func upload(
        httpMethod: Method,
        _ urlString: String,
        headers: [String: String]? = nil,
        data: NSData)
        -> Request
    {
        return Manager.sharedInstance.upload(
            httpMethod,
            urlString,
            headers: headers,
            data: data
        )
    }
    
    public class func upload(request: NSURLRequest, data: NSData) -> Request {
        return Manager.sharedInstance.upload(request, data: data)
    }
    
    public class func upload(
        httpMethod: Method,
        _ urlString: String,
        headers: [String: String]? = nil,
        stream: NSInputStream)
        -> Request
    {
        return Manager.sharedInstance.upload(
            httpMethod,
            urlString,
            headers: headers,
            stream: stream
        )
    }
    
    public class func upload(request: NSURLRequest, stream: NSInputStream) -> Request {
        return Manager.sharedInstance.upload(request, stream: stream)
    }
    
    public class func upload(
        httpMethod: Method,
        _ urlString: String,
        parameters: [String: AnyObject]? = nil,
        headers: [String: String]? = nil,
        encodingMemoryThreshold: UInt64 = Manager.MultipartFormDataEncodingMemoryThreshold,
        multipartFormData: MultipartFormData -> Void)
    {
        Manager.sharedInstance.upload(
            httpMethod,
            urlString,
            parameters: parameters,
            headers: headers,
            encodingMemoryThreshold: encodingMemoryThreshold,
            multipartFormData: multipartFormData
        )
    }
    
    public class func upload(
        request: NSURLRequest,
        parameters: [String: AnyObject]? = nil,
        encodingMemoryThreshold: UInt64 = Manager.MultipartFormDataEncodingMemoryThreshold,
        multipartFormData: MultipartFormData -> Void)
    {
        Manager.sharedInstance.upload(
            request,
            parameters: parameters,
            encodingMemoryThreshold: encodingMemoryThreshold,
            multipartFormData: multipartFormData
        )
    }
    
    // MARK: - Download
    
    public class func download(
        httpMethod: Method,
        _ urlString: String,
        parameters: [String: AnyObject]? = nil,
        encoding: ParameterEncoding? = .URL,
        headers: [String: String]? = nil,
        destination: NSURL)
        -> Request
    {
        return Manager.sharedInstance.download(
            httpMethod,
            urlString: urlString,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            destination: destination
        )
    }
    
    public class func download(request: NSURLRequest, destination: NSURL) -> Request {
        return Manager.sharedInstance.download(request, destination: destination)
    }
    
    public class func download(resumeData: NSData, destination: NSURL) -> Request {
        return Manager.sharedInstance.download(resumeData, destination: destination)
    }
    
}