//
//  Manager.swift
//  Speedy
//
//  Created by Lynch Wong on 3/15/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation

public class Manager {
    
    public static let sharedInstance: Manager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHeaders
        
        return Manager(configuration: configuration)
    }()
    
    public static let defaultHeaders: [String: String]? = {
        return nil
    }()
    
    public let session: NSURLSession
    public let sessionDelegate: SessionDelegate
    
    init(configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        sessionDelegate: SessionDelegate = SessionDelegate()) {
        session = NSURLSession(configuration: configuration, delegate: sessionDelegate, delegateQueue: nil)
        self.sessionDelegate = sessionDelegate
    }
    
    deinit {
        session.invalidateAndCancel()
    }
    
    // MARK: - Request
    
    public func request(
        httpMethod: Method,
        urlString: String,
        parameters: [String: AnyObject]? = nil,
        encoding: ParameterEncoding? = .URL,
        headers: [String: String]? = nil)
        -> Request
    {
        var mutableRequest = URLRequest(httpMethod, urlString, headers)
        mutableRequest = try! encoding!.encode(mutableRequest, parameters: parameters)
        
        return request(mutableRequest)
    }
    
    public func request(request: NSURLRequest) -> Request {
        let task = session.dataTaskWithRequest(request)
        let request = Request(session: session, task: task)
        sessionDelegate[task] = request.delegate
        request.resume()
        return request
    }
    
    // MARK: - Upload
    
    public func upload(
        httpMethod: Method,
        _ urlString: String,
        headers: [String: String]? = nil,
        file: NSURL) -> Request
    {
        let mutableRequest = URLRequest(httpMethod, urlString, headers)
        return upload(mutableRequest, file: file)
    }
    
    public func upload(request: NSURLRequest, file: NSURL) -> Request {
        let task = session.uploadTaskWithRequest(request, fromFile: file)
        let request = Request(session: session, task: task)
        sessionDelegate[task] = request.delegate
        request.resume()
        return request
    }
    
    public func upload(
        httpMethod: Method,
        _ urlString: String,
        headers: [String: String]? = nil,
        data: NSData) -> Request
    {
        let mutableRequest = URLRequest(httpMethod, urlString, headers)
        return upload(mutableRequest, data: data)
    }
    
    public func upload(request: NSURLRequest, data: NSData) -> Request {
        let task = session.uploadTaskWithRequest(request, fromData: data)
        let request = Request(session: session, task: task)
        sessionDelegate[task] = request.delegate
        request.resume()
        return request
    }
    
    public func upload(
        httpMethod: Method,
        _ urlString: String,
        headers: [String: String]? = nil,
        stream: NSInputStream) -> Request
    {
        let mutableRequest = URLRequest(httpMethod, urlString, headers)
        return upload(mutableRequest, stream: stream)
    }
    
    public func upload(request: NSURLRequest, stream: NSInputStream) -> Request {
        let task = session.uploadTaskWithStreamedRequest(request)
        let request = Request(session: session, task: task)
        request.delegate.uploadStream = stream
        sessionDelegate[task] = request.delegate
        request.resume()
        return request
    }
    
    public static let MultipartFormDataEncodingMemoryThreshold: UInt64 = 10 * 1024 * 1024
    
    public func upload(
        httpMethod: Method,
        _ urlString: String,
        parameters: [String: AnyObject]? = nil,
        headers: [String: String]? = nil,
        encodingMemoryThreshold: UInt64 = Manager.MultipartFormDataEncodingMemoryThreshold,
        multipartFormData: MultipartFormData -> Void)
    {
        let mutableRequest = URLRequest(httpMethod, urlString, headers)
        upload(mutableRequest, parameters: parameters, encodingMemoryThreshold: encodingMemoryThreshold, multipartFormData: multipartFormData)
    }
    
    public func upload(
        request: NSURLRequest,
        parameters: [String: AnyObject]? = nil,
        encodingMemoryThreshold: UInt64 = Manager.MultipartFormDataEncodingMemoryThreshold,
        multipartFormData: MultipartFormData -> Void)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            
            let formData = MultipartFormData(parameters: parameters)
            multipartFormData(formData)
            
            let mutableRequest = request.mutableCopy() as! NSMutableURLRequest
            mutableRequest.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
            
            let isBackgroundSession = self.session.configuration.identifier != nil
            
            if formData.contentLength < encodingMemoryThreshold && !isBackgroundSession {
                
                let data = formData.encode()
                self.upload(mutableRequest, data: data)
                
            } else {
                
                let tempDirectoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
                let directoryURL = tempDirectoryURL.URLByAppendingPathComponent("com.speedy.manager/multipart.form.data")
                let fileName = NSUUID().UUIDString
                let fileURL = directoryURL.URLByAppendingPathComponent(fileName)
                
                try! NSFileManager.defaultManager().createDirectoryAtURL(directoryURL, withIntermediateDirectories: true, attributes: nil)
                
                formData.writeEncodedDataToDisk(fileURL)
                self.upload(mutableRequest, file: fileURL)
            }
            
        }
    }
    
    // MARK: - Download
    
    public func download(
        httpMethod: Method,
        urlString: String,
        parameters: [String: AnyObject]? = nil,
        encoding: ParameterEncoding? = .URL,
        headers: [String: String]? = nil,
        destination: NSURL)
        -> Request
    {
        var mutableRequest = URLRequest(httpMethod, urlString, headers)
        mutableRequest = try! encoding!.encode(mutableRequest, parameters: parameters)
        
        return download(mutableRequest, destination: destination)
    }
    
    public func download(request: NSURLRequest, destination: NSURL) -> Request {
        let task = session.downloadTaskWithRequest(request)
        let request = Request(session: session, task: task)
        
        if let downloadDelegate = request.delegate as? DownloadTaskDelegate {
            downloadDelegate.destination = destination
        }
        
        sessionDelegate[task] = request.delegate
        request.resume()
        return request
    }
    
    public func download(resumeData: NSData, destination: NSURL) -> Request {
        let task = session.downloadTaskWithResumeData(resumeData)
        let request = Request(session: session, task: task)
        
        if let downloadDelegate = request.delegate as? DownloadTaskDelegate {
            downloadDelegate.destination = destination
        }
        
        sessionDelegate[task] = request.delegate
        request.resume()
        return request
    }
    
    // MARK: - Private Convenience
    
    private func URLRequest(
        httpMethod: Method,
        _ urlString: String,
        _ headers: [String: String]? = nil)
        -> NSMutableURLRequest
    {
        let mutableRequest = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        mutableRequest.HTTPMethod = httpMethod.rawValue
        
        if let headers = headers {
            for (key, value) in headers {
                mutableRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return mutableRequest
    }
    
}