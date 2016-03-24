//
//  SessionDelegate.swift
//  Speedy
//
//  Created by Lynch Wong on 3/15/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation

public class SessionDelegate: NSObject, NSURLSessionDelegate {
    
    private var tasks: [Int: TaskDelegate] = [:]
    
    subscript(task: NSURLSessionTask) -> TaskDelegate? {
        get {
            
            return tasks[task.taskIdentifier]
        }
        set {
            tasks[task.taskIdentifier] = newValue
        }
    }

    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("didBecomeInvalidWithError")
    }
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        print("didReceiveChallenge")
        completionHandler(NSURLSessionAuthChallengeDisposition.PerformDefaultHandling, nil)
    }
    
    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
    }

}

extension SessionDelegate: NSURLSessionTaskDelegate {
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        print("willPerformHTTPRedirection")
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        print("didReceiveChallenge")
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        print("needNewBodyStream")
        if let delegate = self[task] {
            delegate.URLSession(session,
                task: task,
                needNewBodyStream: completionHandler)
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        print("didSendBodyData")
        if let delegate = self[task] as? UploadTaskDelegate {
            delegate.URLSession(session, task:
                task, didSendBodyData: bytesSent,
                totalBytesSent: totalBytesSent,
                totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        print("didCompleteWithError")
        if let error = error {
            print(error.localizedDescription)
        }
        if let delegate = self[task] {
            delegate.URLSession(session, task: task, didCompleteWithError: error)
        }
    }
    
}

extension SessionDelegate: NSURLSessionDataDelegate {

    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        print("didReceiveResponse")
        completionHandler(.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {
        print("didBecomeDownloadTask")
    }
    
    @available(iOS 9.0, *)
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) {
        print("didBecomeStreamTask")
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if let delegate = self[dataTask] as? DataTaskDelegate {
            delegate.URLSession(session, dataTask: dataTask, didReceiveData: data)
        }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        print("willCacheResponse")
        completionHandler(proposedResponse)
    }

}

extension SessionDelegate: NSURLSessionDownloadDelegate {
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
//        print("didFinishDownloadingToURL")
        if let delegate = self[downloadTask] as? DownloadTaskDelegate {
            delegate.URLSession(session,
                downloadTask: downloadTask,
                didFinishDownloadingToURL: location)
        }
    }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//        print("didWriteData")
        if let delegate = self[downloadTask] as? DownloadTaskDelegate {
            delegate.URLSession(session,
                downloadTask: downloadTask,
                didWriteData: bytesWritten,
                totalBytesWritten: totalBytesWritten,
                totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    } 
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
//        print("didResumeAtOffset")
        if let delegate = self[downloadTask] as? DownloadTaskDelegate {
            delegate.URLSession(session,
                downloadTask: downloadTask,
                didResumeAtOffset: fileOffset,
                expectedTotalBytes: expectedTotalBytes)
        }
    }
    
}