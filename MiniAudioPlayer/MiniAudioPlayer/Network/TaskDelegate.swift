//
//  TaskDelegate.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/31.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

/** The Task delegate is responsible for handling all delegate callbacks for the underlying task as well as executing all operations attached to the serial operation queue upon task completion. */
open class TaskDelegate: NSObject {
    // MARK: Properties
    
    /// The serial operation queue used to execute all operations after the task completes.
    open let queue: OperationQueue
    
    /// The data returned by the server.
    public var data: Data? { return nil }
    
    /// The error generated throughout the lifecyle of the task.
    public var error: Error?
    
    var task: URLSessionTask? {
        set {
            taskLock.lock(); defer { taskLock.unlock() }
            _task = newValue
        }
        get {
            taskLock.lock(); defer { taskLock.unlock() }
            return _task
        }
    }
    
    var initialResponseTime: CFAbsoluteTime?
    var credential: URLCredential?
    
    /// URLSessionTaskMetrics
    var metrics: AnyObject?
    
    private var _task: URLSessionTask? {
        didSet { reset() }
    }
    private let taskLock = NSLock()
    
    // MARK: - Lifecycle
    init(task: URLSessionTask?) {
        _task = task
        
        self.queue = {
            let operationQueue = OperationQueue()
            
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.isSuspended = true
            operationQueue.qualityOfService = .utility
            
            return operationQueue
        }()
    }
    
    func reset() {
        error = nil
        initialResponseTime = nil
    }
    
    //MARK: - URLSessionTaskDelegate
    
    var taskWillPerformHTTPRedirection: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest) -> URLRequest?)?
    var taskDidReceiveChallenge: ((URLSession, URLSessionTask, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    var taskNeedNewBodyStream: (() -> Void)?
}
