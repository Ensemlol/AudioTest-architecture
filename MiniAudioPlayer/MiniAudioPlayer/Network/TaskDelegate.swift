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





// MARK: -
class DataTaskDelegate: TaskDelegate, URLSessionDataDelegate {
    
    // MARK: - Properties
    
    var dataTask: URLSessionDataTask { return task as! URLSessionDataTask }
    
    override var data: Data? {
        if dataStream != nil {
            return nil
        } else {
            return mutableData
        }
    }
    
    var progress: Progress
    var progressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?
    
    var dataStream: ((_ data: Data) -> Void)?
    
    private var totalBytesReceived: Int64 = 0
    private var mutableData: Data
    
    private var expectedContentLength: Int64?
    
    // MARK: - lifecycle
    
    override init(task: URLSessionTask?) {
        mutableData = Data()
        progress = Progress(totalUnitCount: 0)
        
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        
        progress = Progress(totalUnitCount: 0)
        totalBytesReceived = 0
        mutableData = Data()
        expectedContentLength = nil
    }
    
    // MARK: - URLSessionDataDelegate
    
    var dataTaskDidReceiveResponse: ((URLSession, URLSessionDataTask, URLResponse) -> URLSession.ResponseDisposition)?
    var dataTaskDidBecomeDownloadTask: ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)?
    var dataTaskDidReceiveData: ((URLSession, URLSessionDataTask, Data) -> Void)?
    var dataTaskWillCacheResponse: ((URLSession, URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)?
    
    // MARK: - urlSession
    
    func urlSession(_ session: URLSession,
                     dataTask: URLSessionDataTask,
          didReceive response: URLResponse,
            completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        var disposition: URLSession.ResponseDisposition = .allow
        expectedContentLength = response.expectedContentLength
        
        if let dataTaskDidReceiveResponse = dataTaskDidReceiveResponse {
            disposition = dataTaskDidReceiveResponse(session, dataTask, response)
        }
        
        completionHandler(disposition)
    }
    
    func urlSession(_ session: URLSession,
                     dataTask: URLSessionDataTask,
       didBecome downloadTask: URLSessionDownloadTask) {
       
        dataTaskDidBecomeDownloadTask?(session, dataTask, downloadTask)
    }
    
    func urlSession(_ session: URLSession,
                     dataTask: URLSessionDataTask,
              didReceive data: Data) {
        
        if initialResponseTime == nil {
            initialResponseTime = CFAbsoluteTimeGetCurrent()
        }
        
        if let dataTaskDidReceiveData = dataTaskDidReceiveData {
            dataTaskDidReceiveData(session, dataTask, data)
        } else {
            if let dataStream = dataStream {
                // FIXME: - todo
                dataStream(data)
            } else {
                mutableData.append(data)
            }
            
            let bytesReceived = Int64(data.count)
            totalBytesReceived += bytesReceived
            let totalBytesExpected = dataTask.response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            
            progress.totalUnitCount = totalBytesExpected
            progress.completedUnitCount = totalBytesReceived
            
            if let progressHandler = progressHandler {
                progressHandler.queue.async { progressHandler.closure(self.progress) }
            }
        }
    }
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse: CachedURLResponse,
                    completionHandler: @escaping (CachedURLResponse?) -> Void) {
        
        var cachedResponse: CachedURLResponse? = proposedResponse
        if let dataTaskWillCacheResponse = dataTaskWillCacheResponse {
            cachedResponse = dataTaskWillCacheResponse(session, dataTask, proposedResponse)
        }
        completionHandler(cachedResponse)
    }
}

// MARK: -

class DownloadTaskDelegate: TaskDelegate, URLSessionDownloadDelegate {
    
    // MARK: - Properties
    
    var downloadTask: URLSessionDownloadTask { return task as! URLSessionDownloadTask }
    
    var progress: Progress
    var progressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?
    
    var  resumeData: Data?
    override var data: Data? { return resumeData }
    
    
    
    var temporaryURL: URL?
    var destinationURL: URL?
    
    var fileURL: URL?
    
    override init(task: URLSessionTask?) {
        progress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        
        progress = Progress(totalUnitCount: 0)
        resumeData = nil
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    var downloadTaskDidFinishDownloadingToURL:(URLSession, URLSessionDownloadTask, URL) -> URL
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL) {
        
        
    }
}
