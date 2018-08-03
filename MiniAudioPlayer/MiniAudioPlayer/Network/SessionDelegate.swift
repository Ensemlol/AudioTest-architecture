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
    
    weak var sessionManager: SessionManager?
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
