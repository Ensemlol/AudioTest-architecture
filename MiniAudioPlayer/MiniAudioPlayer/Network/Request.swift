//
//  Request.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/31.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation



/** A type that can inspect and optionally adapt a `URLRequest` in some manner if necessary. */
public protocol RequestAdapter {
    
    /// Inspect and adapts the specified `URLRequest` in some manner if necessary and returns the result.
    ///
    /// - Parameter urlRequest: The URL request to adapt.
    ///
    /// - Returns: The adapted `URLRequest`.
    ///
    /// - Throws: An `Error` if the adaptation encounters an error.
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest
}




/// A dictionary of headers to apply to a `URLRequest`.
public typealias HTTPHeaders = [String: String]




protocol TaskConvertible {
    func task(session: URLSession, adapter: RequestAdapter, queue: DispatchQueue) throws -> URLSessionTask
}





// MARK: - Responsible for sending a request and receiving the response and associated data from the server, as well as managing its underlying `URLSession Task`.
open class Request {
    
    // MARK: - Helper Types
    /// A closure executed when monitoring upload or download progress of a request.
    public typealias ProgressHandler = (Progress) -> ()
    
    enum RequestTask {
        case data(TaskConvertible?, URLSessionTask?)
        case download(TaskConvertible?, URLSessionTask?)
        case upload(TaskConvertible?, URLSessionDelegate?)
        case stream(TaskConvertible?, URLSessionTask?)
    }
    
    // MARK: - properties
    /// The delegate for the underlying task.
    open internal(set) var delegate: TaskDelegate {
        get {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            return taskDelegate
        }
        set {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            taskDelegate = newValue
        }
    }
    
    /// The underlying task.
    open var task: URLSessionTask? { return delegate.task }
    
    /// The session belonging to the underlying task.
    open let session: URLSession
    
    /// The request sent or to be sent to the server.
    open var request: URLRequest? { return task?.originalRequest }
    
    private var taskDelegate: TaskDelegate
    private var taskDelegateLock = NSLock()
    
    init(session: URLSession, requestTask: RequestTask, error: Error? = nil) {
        self.session = session
        
//        delegate.error = error
//        delegate.queue.addOperation {
//            
//        }
    }
}

extension URLRequest {
    
    /// Creates an instance with the specified `method`, `urlString` and `headers`.
    ///
    /// - Parameters:
    ///   - url:     The URL.
    ///   - method:  The HTTP method.
    ///   - headers: The HTTP headers. `nil` by default.
    ///
    /// - Throws:    The new `URLRequest` instance.
    public init(url: URLConvertible, method: HTTPMethod, headers: HTTPHeaders? = nil) throws {
        let url = try url.asURL()
        
        self.init(url: url)
        
        httpMethod = method.rawValue
        
        if let headers = headers {
            for (headerField, headerValue) in headers {
                setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
    }
    
    func adapt(using adapter: RequestAdapter?) throws -> URLRequest {
        guard let adapter = adapter else { return self }
        return try adapter.adapt(self)
    }
}

// MARK: - Specific type of `Request` that manages an underlying `URLSessionDataTask`.
open class DataRequest: Request {
    
    // MARK: - Helper Types
    struct Requestable: TaskConvertible {
        let urlRequest: URLRequest
        
        func task(session: URLSession, adapter: RequestAdapter, queue: DispatchQueue) throws -> URLSessionTask {
            do {
                let urlRequest = try self.urlRequest.adapt(using: adapter)
                return queue.sync { session.dataTask(with: urlRequest) }
            } catch {
                throw AdaptError(error: error)
            }
        }
    }
    
    // MARK: Properties
    /// The request sent or to be sent to the server.
    open override var request: URLRequest? {
        if let request = super.request { return request }
//        if let requestable =  {
//            <#statements#>
//        }
        return nil
    }
}

// MARK: - Specific type of `Request` that manages an underlying `URLSessionUploadTask`.
open class UploadRequest {
    
}
