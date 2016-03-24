//
//  Request.swift
//  Speedy
//
//  Created by Lynch Wong on 3/15/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation

public class Request {
    
    public let session: NSURLSession
    
    public let delegate: TaskDelegate
    
    public var task: NSURLSessionTask { return delegate.task }
    
    public var progress: NSProgress { return delegate.progress }
    
    public var request: NSURLRequest? { return task.originalRequest }
    
    public var response: NSHTTPURLResponse? { return task.response as? NSHTTPURLResponse }
    
    public var startTime: CFAbsoluteTime?
    public var endTime: CFAbsoluteTime?
    
    init(session: NSURLSession, task: NSURLSessionTask) {
        self.session = session
        
        switch task {
            case is NSURLSessionUploadTask:
                delegate = UploadTaskDelegate(task: task)
            case is NSURLSessionDataTask:
                delegate = DataTaskDelegate(task: task)
            case is NSURLSessionDownloadTask:
                delegate = DownloadTaskDelegate(task: task)
            default:
                delegate = TaskDelegate(task: task)
        }
        
        delegate.queue.addOperationWithBlock { self.endTime = CFAbsoluteTimeGetCurrent() }
    }
    
    public func resume() {
        if startTime == nil { startTime = CFAbsoluteTimeGetCurrent() }
        task.resume()
    }
    
    public func cancel() {
        task.cancel()
    }
    
    public func suspend() {
        task.suspend()
    }
    
}

public class TaskDelegate: NSObject, NSURLSessionTaskDelegate {
    
    public let queue: NSOperationQueue

    public let task: NSURLSessionTask
    
    public let progress: NSProgress
    
    public var data: NSMutableData?
    public var error: NSError?
    
    public var uploadStream: NSInputStream?
    
    init(task: NSURLSessionTask) {
        self.task = task
        progress = NSProgress(totalUnitCount: 0)
        queue = {
            let operationQueue = NSOperationQueue()
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.suspended = true
            return operationQueue
        }()
    }
    
    deinit {
        queue.cancelAllOperations()
        queue.suspended = false
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        completionHandler(request)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(.PerformDefaultHandling, nil)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        completionHandler(uploadStream)
    }
    
//    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
//        
//    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let error = error {
            self.error = error
        }
        queue.suspended = false
    }

}

public class DataTaskDelegate: TaskDelegate, NSURLSessionDataDelegate {

    public var dataTask: NSURLSessionDataTask? { return task as? NSURLSessionDataTask }
    
    public var expectedContentLength: Int64?
    public var totalBytesReceived: Int64 = 0
    public var dataProgress: ((Int64, Int64, Int64) -> Void)?
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        expectedContentLength = response.expectedContentLength
        completionHandler(.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
        
    }
    
    @available(iOS 9.0, *)
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) {
        
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if self.data == nil { self.data = NSMutableData() }
        self.data?.appendData(data)
        
        totalBytesReceived += data.length
        let totalBytesExpected = dataTask.response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
        
        progress.totalUnitCount = totalBytesExpected
        progress.completedUnitCount = totalBytesReceived
        
        dataProgress?(Int64(data.length), totalBytesReceived, totalBytesExpected)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        completionHandler(proposedResponse)
    }

}

public class UploadTaskDelegate: TaskDelegate {
    
    public var uploadProgress: ((Int64, Int64, Int64) -> Void)?
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        progress.totalUnitCount = totalBytesExpectedToSend
        progress.completedUnitCount = totalBytesSent
        
        uploadProgress?(bytesSent, totalBytesSent, totalBytesExpectedToSend)
    }
    
}

public class DownloadTaskDelegate: TaskDelegate, NSURLSessionDownloadDelegate {
    
    public var destination: NSURL?
    public var downloadProgress: ((Int64, Int64, Int64) -> Void)?

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        do {
            try NSFileManager.defaultManager().moveItemAtURL(location, toURL: destination!)
        } catch {
            self.error = error as NSError
        }
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progress.totalUnitCount = totalBytesExpectedToWrite
        progress.completedUnitCount = totalBytesWritten
        downloadProgress?(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        progress.totalUnitCount = expectedTotalBytes
        progress.completedUnitCount = fileOffset
    }
    
}

extension Request {
    
    public func progress(closure: (Int64, Int64, Int64) -> Void) -> Self {
        if let delegate = delegate as? DataTaskDelegate {
            delegate.dataProgress = closure
        } else if let delegate = delegate as? UploadTaskDelegate {
            delegate.uploadProgress = closure
        } else if let delegate = delegate as? DownloadTaskDelegate {
            delegate.downloadProgress = closure
        }
        return self
    }
    
    public func responseString(closure: Response<String, NSError> -> Void) -> Self {
        delegate.queue.addOperationWithBlock {
            let result: Result<String, NSError> = {
                if let error = self.delegate.error {
                    return .Failure(error)
                } else {
                    return .Success(String(data: self.delegate.data!, encoding: NSUTF8StringEncoding)!)
                }
            }()
            
            let response = Response(request: self.request, response: self.response, data: self.delegate.data, result: result)
            
            closure(response)
        }
        return self
    }
    
    public func responseJSON(closure: Response<AnyObject, NSError> -> Void) -> Self {
        delegate.queue.addOperationWithBlock {
            let result: Result<AnyObject, NSError> = {
                if let error = self.delegate.error {
                    return .Failure(error)
                } else {
                    do {
                        let object = try NSJSONSerialization.JSONObjectWithData(self.delegate.data!, options: NSJSONReadingOptions.AllowFragments)
                        return .Success(object)
                    } catch {
                        return .Failure(error as NSError)
                    }
                }
            }()
            
            let response = Response(request: self.request, response: self.response, data: self.delegate.data, result: result)
            
            closure(response)
        }
        return self
    }
    
    public func responseData(closure: Response<NSData, NSError> -> Void) -> Self {
        delegate.queue.addOperationWithBlock {
            let result: Result<NSData, NSError> = {
                if let error = self.delegate.error {
                    return .Failure(error)
                } else {
                    return .Success(self.delegate.data!)
                }
            }()
            
            let response = Response(request: self.request, response: self.response, data: self.delegate.data, result: result)
            
            closure(response)
        }
        return self
    }
    
}
