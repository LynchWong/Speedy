//
//  MultipartFormData.swift
//  Speedy
//
//  Created by Lynch Wong on 3/16/16.
//  Copyright © 2016 Lynch Wong. All rights reserved.
//

import Foundation
import MobileCoreServices

public class MultipartFormData {
    
    struct EncodingCharacters {
        static let CRLF = "\r\n"
    }
    
    struct BoundaryGenerator {
        enum BoundaryType {
            case Initial, Encapsulated, Final
        }
        
        static func randomBoundary() -> String {
            return String(format: "speedy.boundary.%08x%08x", arc4random(), arc4random())
        }
        
        static func boundaryData(boundaryType: BoundaryType, boundary: String) -> NSData {
            let boundaryText: String
            
            switch boundaryType {
                case .Initial:
                    boundaryText = "--\(boundary)\(EncodingCharacters.CRLF)"
                case .Encapsulated:
                    boundaryText = "\(EncodingCharacters.CRLF)--\(boundary)\(EncodingCharacters.CRLF)"
                case .Final:
                    boundaryText = "\(EncodingCharacters.CRLF)--\(boundary)--\(EncodingCharacters.CRLF)"
            }
            
            return boundaryText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        }
    }
    
    class BodyPart {
        let headers: [String: String]
        let bodyStream: NSInputStream
        let bodyContentLength: UInt64
        var hasInitialBoundary = false
        var hasFinalBoundary = false
        
        init(headers: [String: String], bodyStream: NSInputStream, bodyContentLength: UInt64) {
            self.headers = headers
            self.bodyStream = bodyStream
            self.bodyContentLength = bodyContentLength
        }
    }
    
    public let boundary: String
    public var contentType: String { return "multipart/form-data; boundary=\(boundary)" }
    public var contentLength: UInt64 { return bodyParts.reduce(0, combine: { return $0 + $1.bodyContentLength }) }
    
    private var bodyParts: [BodyPart] = []
    private let streamBufferSize: Int
    
    public init(parameters: [String: AnyObject]? = nil) {
        boundary = BoundaryGenerator.randomBoundary()
        streamBufferSize = 1024
        
        if let parameters = parameters {
            parametersBodyPart(parameters)
        }
    }
    
    private func parametersBodyPart(parameters: [String: AnyObject]) {
        for (key, value) in ParameterEncoding.URL.query(parameters) {
            let headers = ["Content-Disposition": "form-data; name=\"\(key)\""]
            let data = value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            let bodyStream = NSInputStream(data: data)
            let bodyContentLength = UInt64(data.length)
            
            addBodyPart(headers, bodyStream: bodyStream, bodyContentLength: bodyContentLength)
        }
    }
    
    // MARK: - Body Parts
    
    public func addBodyPart(headers: [String: String], bodyStream: NSInputStream, bodyContentLength: UInt64) {
        let bodyPart = BodyPart(headers: headers, bodyStream: bodyStream, bodyContentLength: bodyContentLength)
        bodyParts.append(bodyPart)
    }
    
    public func addBodyPart(bodyStream: NSInputStream, bodyContentLength: UInt64, name: String, fileName: String, mimeType: String) {
        let headers = contentHeader(name, fileName: fileName, mimeType: mimeType)
        addBodyPart(headers, bodyStream: bodyStream, bodyContentLength: bodyContentLength)
    }
    
    public func addBodyPart(data: NSData, name: String) {
        let headers = contentHeader(name)
        let bodyStream = NSInputStream(data: data)
        let bodyContentLength = UInt64(data.length)
        addBodyPart(headers, bodyStream: bodyStream, bodyContentLength: bodyContentLength)
    }
    
    public func addBodyPart(data: NSData, name: String, mimeType: String) {
        let headers = contentHeader(name, mimeType: mimeType)
        let bodyStream = NSInputStream(data: data)
        let bodyContentLength = UInt64(data.length)
        addBodyPart(headers, bodyStream: bodyStream, bodyContentLength: bodyContentLength)
    }
    
    public func addBodyPart(data: NSData, name: String, fileName: String, mimeType: String) {
        let headers = contentHeader(name, fileName: fileName, mimeType: mimeType)
        let bodyStream = NSInputStream(data: data)
        let bodyContentLength = UInt64(data.length)
        addBodyPart(headers, bodyStream: bodyStream, bodyContentLength: bodyContentLength)
    }
    
    public func addBodyPart(fileURL: NSURL, name: String) {
        
        if let fileName = fileURL.lastPathComponent, pathExtension = fileURL.pathExtension {
            let mimeType = mimeTypeForPathExtension(pathExtension)
            addBodyPart(fileURL, name: name, fileName: fileName, mimeType: mimeType)
        }
    }
    
    public func addBodyPart(fileURL: NSURL, name: String, fileName: String, mimeType: String) {
        guard fileURL.fileURL else {
            return
        }
        
        var isDirectory: ObjCBool = false
        guard let path = fileURL.path
            where NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory) && !isDirectory else
        {
            return
        }
        
        var bodyContentLength: UInt64?
        if let path = fileURL.path,
            fileSize = try? NSFileManager.defaultManager().attributesOfItemAtPath(path)[NSFileSize] as? NSNumber
        {
            bodyContentLength = fileSize?.unsignedLongLongValue
        }
        guard let length = bodyContentLength else {
            return
        }
        
        guard let bodyStream = NSInputStream(URL: fileURL) else {
            return
        }
        
        let headers = contentHeader(name, fileName: fileName, mimeType: mimeType)
        addBodyPart(headers, bodyStream: bodyStream, bodyContentLength: length)
    }
    
    public func encode() -> NSData {
        let mutableData = NSMutableData()
        
        bodyParts.first?.hasInitialBoundary = true
        bodyParts.last?.hasFinalBoundary = true
        
        for bodyPart in bodyParts {
            mutableData.appendData(encodeBodyPart(bodyPart))
        }
        
        return mutableData
    }
    
    public func writeEncodedDataToDisk(fileURL: NSURL) {
        guard fileURL.fileURL else {
            return
        }
        
        guard let path = fileURL.path where !NSFileManager.defaultManager().fileExistsAtPath(path) else {
            return
        }
        
        guard let possibleOutputStream = NSOutputStream(URL: fileURL, append: false) else {
            return
        }
        
        let outputStream = possibleOutputStream
        
        outputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream.open()
        
        bodyParts.first?.hasInitialBoundary = true
        bodyParts.last?.hasFinalBoundary = true
        
        for bodyPart in bodyParts {
            writeBodyPart(bodyPart, toOutputStream: outputStream)
        }
        
        outputStream.close()
        outputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    // MARK: - Private - Writing Body Part to Output Stream
    
    private func writeBodyPart(bodyPart: BodyPart, toOutputStream outputStream: NSOutputStream) {
        writeInitialBoundaryDataForBodyPart(bodyPart, toOutputStream: outputStream)
        writeHeaderDataForBodyPart(bodyPart, toOutputStream: outputStream)
        writeBodyStreamForBodyPart(bodyPart, toOutputStream: outputStream)
        writeFinalBoundaryDataForBodyPart(bodyPart, toOutputStream: outputStream)
    }
    
    private func writeInitialBoundaryDataForBodyPart(bodyPart: BodyPart, toOutputStream outputStream: NSOutputStream) {
        let initialBoundaryData = bodyPart.hasInitialBoundary ? initialBoundaaryData() : encapsulatedBoundaaryData()
        writeData(initialBoundaryData, toOutputStream: outputStream)
    }
    
    private func writeHeaderDataForBodyPart(bodyPart: BodyPart, toOutputStream outputStream: NSOutputStream) {
        let headerData = encodeHeaderDataForBodyPart(bodyPart)
        writeData(headerData, toOutputStream: outputStream)
    }
    
    private func writeBodyStreamForBodyPart(bodyPart: BodyPart, toOutputStream outputStream: NSOutputStream) {
        let inputStream = bodyPart.bodyStream
        
        inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream.open()
        
        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](count: streamBufferSize, repeatedValue: 0)
            let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)
            
            if bytesRead > 0 {
                if buffer.count != bytesRead {
                    buffer = Array(buffer[0..<bytesRead])
                }
                writeBuffer(&buffer, toOutputStream: outputStream)
            } else if bytesRead < 0 {
                
            } else {
                break
            }
        }
        
        inputStream.close()
        inputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    private func writeFinalBoundaryDataForBodyPart(bodyPart: BodyPart, toOutputStream outputStream: NSOutputStream) {
        if bodyPart.hasFinalBoundary {
            let finalBoundaryData = finalBoundaaryData()
            writeData(finalBoundaryData, toOutputStream: outputStream)
        }
    }
    
    private func writeData(data: NSData, toOutputStream outputStream: NSOutputStream) {
        var buffer = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&buffer, length: data.length)
        writeBuffer(&buffer, toOutputStream: outputStream)
    }
    
    private func writeBuffer(inout buffer: [UInt8], toOutputStream outputStream: NSOutputStream) {
        var bytesToWrite = buffer.count
        
        while bytesToWrite > 0 {
            if outputStream.hasSpaceAvailable {
                let bytesWrriten = outputStream.write(buffer, maxLength: bytesToWrite)
                
                if bytesWrriten < 0 {
                    break
                }
                
                bytesToWrite -= bytesWrriten
                
                if bytesWrriten > 0 {
                    buffer = Array(buffer[bytesWrriten..<buffer.count])
                }
            }
        }
    }
    
    // MARK: - Private - Body Part Encoding
    
    private func encodeBodyPart(bodyPart: BodyPart) -> NSData {
        let data = NSMutableData()
        
        let initialData = bodyPart.hasInitialBoundary ? initialBoundaaryData() : encapsulatedBoundaaryData()
        data.appendData(initialData)
        
        let headerData = encodeHeaderDataForBodyPart(bodyPart)
        data.appendData(headerData)
        
        let bodyStreamData = encodeBodyStreamDataForBodyPart(bodyPart)
        data.appendData(bodyStreamData)
        
        if bodyPart.hasFinalBoundary {
            data.appendData(finalBoundaaryData())
        }
        
        return data
    }
    
    private func encodeHeaderDataForBodyPart(bodyPart: BodyPart) -> NSData {
        var headerText = ""
        
        for (key, value) in bodyPart.headers {
            headerText += "\(key): \(value)\(EncodingCharacters.CRLF)"
        }
        headerText += EncodingCharacters.CRLF
        
        return headerText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
    
    private func encodeBodyStreamDataForBodyPart(bodyPart: BodyPart) -> NSData {
        let inputStream = bodyPart.bodyStream
        
        let data = NSMutableData()
        
        inputStream.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        inputStream.open()
        
        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](count: streamBufferSize, repeatedValue: 0)
            let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)
            
            if bytesRead > 0 {
                data.appendBytes(buffer, length: bytesRead)
            }
        }
        
        inputStream.close()
        inputStream.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        return data
    }
    
    // MARK:- Private - Mime Type
    
    private func mimeTypeForPathExtension(pathExtension: String) -> String {
        if let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue(),
            contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
        {
            return contentType as String
        }
        return "application/octet-stream"
    }
    
    // MARK: - Private - Content Headers
    
    private func contentHeader(name: String) -> [String: String] {
        return ["Content-Disposition": "form-data; name=\"\(name)\""]
    }
    
    private func contentHeader(name: String, mimeType: String) -> [String: String] {
        return [
            "Content-Disposition": "form-data; name=\"\(name)\"",
            "Content-Type": "\(mimeType)"
        ]
    }
    
    private func contentHeader(name: String, fileName: String, mimeType: String) -> [String: String] {
        return [
            "Content-Disposition": "form-data; name=\"\(name)\"; filename=\"\(fileName)\"",
            "Content-Type": "\(mimeType)"
        ]
    }
    
    // MARK: - Private - Boundary Encoding
    
    private func initialBoundaaryData() -> NSData {
        return BoundaryGenerator.boundaryData(.Initial, boundary: boundary)
    }
    
    private func encapsulatedBoundaaryData() -> NSData {
        return BoundaryGenerator.boundaryData(.Encapsulated, boundary: boundary)
    }
    
    private func finalBoundaaryData() -> NSData {
        return BoundaryGenerator.boundaryData(.Final, boundary: boundary)
    }
    
}
