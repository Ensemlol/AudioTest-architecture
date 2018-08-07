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

// MARK: -

/// A closure executed when the `RequestRetruer` determines whether a `Request` should be retried or not.
public typealias RequestRetryCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval) -> Void

/// A type that determines whether a request should be retrued after being executed by the specified session manager and encountering an error.
public protocol RequestRetrier {
    
    /// DeterMines whether the `Request` should be retried by calling the `completion` closure.
    ///
    /// This operation is fully asynchronous. Any amount of time can be taken to determine whether the request needs to be retried. The one requirement is that the completion closure is called to ensure the request is properly cleaned up after.
    ///
    /// - Parameters:
    ///   - manager:    The session manage the request was executed on.
    ///   - request:    The request that failed due to the encountered error.
    ///   - error:      The error encountered when executing the request.
    ///   - completion: The completion closure to be executed when retry decision has been determined.
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion)
}




/// A dictionary of headers to apply to a `URLRequest`.
public typealias HTTPHeaders = [String: String]




protocol TaskConvertible {
    func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask
}





// MARK: - Responsible for sending a request and receiving the response and associated data from the server, as well as managing its underlying `URLSession Task`.
open class Request {
    
    // MARK: - Helper Types
    /// A closure executed when monitoring upload or download progress of a request.
    public typealias ProgressHandler = (Progress) -> ()
    
    enum RequestTask {
        case data(TaskConvertible?, URLSessionTask?)
        case download(TaskConvertible?, URLSessionTask?)
        case upload(TaskConvertible?, URLSessionTask?)
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
    
    /// The response received from the server, if any.
    open var response: HTTPURLResponse? { return task?.response as? HTTPURLResponse }
    
    /// The number of times the request has been retried.
    open internal(set) var retryCount: UInt = 0
    
    let originalTask: TaskConvertible?
    
    var startTime: CFAbsoluteTime?
    var endTime: CFAbsoluteTime?
    
    var validations: [() -> Void] = []
    
    private var taskDelegate: TaskDelegate
    private var taskDelegateLock = NSLock()
    
    init(session: URLSession, requestTask: RequestTask, error: Error? = nil) {
        self.session = session
        
        switch requestTask {
        case .data(let originalTask, let task):
            taskDelegate = DataTaskDelegate(task: task)
            self.originalTask = originalTask
        case .download(let originalTask, let task):
            taskDelegate = DownloadTaskDelegate(task: task)
            self.originalTask = originalTask
        case .upload(let originalTask, let task):
            taskDelegate = UploadTaskDelegate(task: task)
            self.originalTask = originalTask
        case .stream(let originalTask, let task):
            taskDelegate = TaskDelegate(task: task)
            self.originalTask = originalTask
        }
        
        delegate.error = error
        delegate.queue.addOperation { self.endTime = CFAbsoluteTimeGetCurrent() }
    }
    
    // MARK: - State
    
    /// Resumes the request.
    open func resume() {
        guard let task = task else { delegate.queue.isSuspended = false ; return }
        
        if startTime == nil { startTime = CFAbsoluteTimeGetCurrent() }
        
        task.resume()
        
        NotificationCenter.default.post(name: Notification.Name.Task.DidResume,
                                        object: self,
                                        userInfo: [Notification.Key.Task: task])
    }
    
    /// Suspends the request.
    open func suspend() {
        guard let task = task else { return }
        
        task.suspend()
        
        NotificationCenter.default.post(name: Notification.Name.Task.DidSuspend,
                                        object: self,
                                        userInfo: [Notification.Key.Task: task])
    }
    
    /// Cancels the request.
    open func cancel() {
        guard let task = task else { return }
        
        task.cancel()
        
        NotificationCenter.default.post(name: Notification.Name.Task.DidCancel,
                                        object: self,
                                        userInfo: [Notification.Key.Task: task])
    }
}

// MARK: - Specific type of `Request` that manages an underlying `URLSessionDataTask`.
open class DataRequest: Request {
    
    // MARK: - Helper Types
    struct Requestable: TaskConvertible {
        let urlRequest: URLRequest
        
        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
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

// MARK: - Specific type of `Request` that manages an underlying `URLSessionDownloadTask`.

open class DownloadRequest: Request {
    
    // MARK: - Helper Types
    
    /// A collection of options to be executed prior to moving a downloaded file from the temporary URL to the destination URL.
    public struct DownloadOptions: OptionSet {
        /// Returns the raw bitmask value of the option and satisfies the `RawRepresentable` protocol.
        public let rawValue: UInt
        
        /// A `DownloadOptions` flag that creates intermediate directories for the destination URL if specified.
        public static let createIntermediateDirectories = DownloadOptions(rawValue: 1 << 0)
        
        /// A `DownloadOptions` flag that removes a previous file from the destination URL if specified.
        public static let removePreviousFile = DownloadOptions(rawValue: 1 << 1)
        
        /// Creates a `downloadFileDestinationOptions` instance with the specified raw value.
        ///
        /// - Parameter rawValue: The raw bitmask value for the option.
        ///
        /// - Returns: A new log level instance.
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
    
    public typealias DownloadFileDestination = (
        _ temporaryURL: URL,
        _ response: HTTPURLResponse) -> (destinationURL: URL, options: DownloadOptions)
}
