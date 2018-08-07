//
//  SessionDelegate.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/8/3.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

open class SessionDelegate: NSObject {
    
    // MARK: URLSessionDelegate Overrides
    
    /// Overrides default behavior for URLSessionDelegate method `urlSession(_:didBecomeInvalidWithError:)`.
    open var sessionDidBecomeInvalidWithError: ((URLSession, Error?) -> Void)?
    
    /// <#Description#>
    open var sessionDidReceiveChallenge:((URLSession, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?
    
    /// <#Description#>
    open var sessionDidReveiveChallengeWithCompletion:((URLSession, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?
    
    /// <#Description#>
    open var sessionDidFinishEvemtsForBackgroundURLSession: ((URLSession) -> Void)?
    
    // MARK: - Properties
    
    var retrier: RequestRetrier?
    weak var sessionManager: SessionManager?
    
    private var requests: [Int: Request] = [:]
    private var lock = NSLock()
    
    open subscript(task: URLSessionTask) -> Request? {
        get {
            lock.lock() ; defer { lock.unlock() }
            return requests[task.taskIdentifier]
        }
        set {
            lock.lock() ; defer { lock.unlock() }
            requests[task.taskIdentifier] = newValue
        }
    }
    
    // MARK: - Lifecycle
    
    /// Initializes the `SessionDelegate` instance.
    public override init() {
        super.init()
    }
    
    /// <#Description#>
    ///
    /// - Parameter aSelector: <#aSelector description#>
    /// - Returns: <#return value description#>
    open override func responds(to aSelector: Selector!) -> Bool {
        return true
    }
}

// MARK: - URLSessionDelegate

extension SessionDelegate: URLSessionDelegate {
    
    /// Tells the delegate that the session has been invalidated.
    ///
    /// - Parameters:
    ///   - session: <#session description#>
    ///   - error: <#error description#>
    open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        sessionDidBecomeInvalidWithError?(session, error)
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - session: <#session description#>
    ///   - challenge: <#challenge description#>
    ///   - completionHandler: <#completionHandler description#>
    open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard sessionDidReceiveChallenge == nil else {
            sessionDidReveiveChallengeWithCompletion?(session, challenge, completionHandler)
            return
        }
    }
}
