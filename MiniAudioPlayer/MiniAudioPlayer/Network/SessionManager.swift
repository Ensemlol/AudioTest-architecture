//
//  SessionManager.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/8/3.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

/// Responsible for creating and managing `Request` objects, as well as their underlying `NSURLSession`.
open class SessionManager {
    
    // MARK: - Helper Types
    
    /// Defines whether the `MultipartFormData` encoding was successful and contains result of the encoding as associated values.
    ///
    /// - success: Represents a successful `MultipartFormData` encoding and contains the new `UploadRequest` along with streaming information.
    ///
    /// - failure: Used to represent a failure in the `MultipartFormData` encoding and also contains the encoding error.
    public enum MultipartFormDataEncodingResult {
        case success(request: UploadRequest, streamingFromDisk: Bool, streamFileURL: URL?)
        case failure(Error)
    }
    
    //MARK: - Properties
    
    /// A defaut instance of `SessionManager`, used by top-level "Alamofire" request methods, and suitable for use
    /// directly for any ad hoc requests.
    open static let `default`: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        return SessionManager(configuration: configuration)
    }()
    
    /// Creates default values for the "Accept-Encoding", "Accept-Language" and "User-Agent" headers.
    open static let defaultHTTPHeaders: HTTPHeaders = {
        // Accept-Encoding HTTP Headers: See https://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0, compress;q=0.5"
        
        
        /// Accept-Language HTTP Headers; See https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = Locale.preferredLanguages.prefix(6).enumerated().map { index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
        }.joined(separator: ", ")
        
        let userAgent: String = {
            if let info = Bundle.main.infoDictionary {
                let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
                let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
                let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"
                
                let osNameVersion: String = {
                    let version = ProcessInfo.processInfo.operatingSystemVersion
                    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
                    
                    let osName: String = {
                        #if os(iOS)
                            return "iOS"
                        #elseif os(watchOS)
                            return "watchOS"
                        #elseif os(tvOS)
                            return "tvOS"
                        #elseif os(macOS)
                            return "OS X"
                        #elseif os(Linux)
                            return "Linux"
                        #else
                            return "Unknown"
                        #endif
                    }()
                    
                    return "\(osName) \(versionString)"
                }()
                
                let alamofireVersion: String = {
                    guard let afInfo = Bundle(for: SessionManager.self).infoDictionary, let build = afInfo["CFBundleShortVersionString"] else { return "Unknown" }
                    return "Alamofire\(build)"
                }()
                
                return "\(executable)\(appVersion)\(bundle); build:\(appBuild); \(osNameVersion)\(alamofireVersion)"
            }
            
            return "Alamofire"
        }()
        
        return [
            "Accept-Encoding": acceptEncoding,
            "Accept-Language": acceptLanguage,
            "User-Agent": userAgent
        ]
    }()
    
    /// Default memory threshold used when encoding `MultipartFormData` in bytes.
    static let multipartFormDataEncodingMemoryThreshold: UInt64 = 10_000_000
    
    /// The underlying session
    open let session: URLSession
    
    /// The Session delegate handling all the task and session delegate callbacks.
    open let delegate: SessionDelegate
    
    /// Whether to start requests immediately after being constructed. `true` by default.
    open var startRequestsImmediately: Bool = true
    
    /// The request adapter called each time a new request is created.
    open var adapter: RequestAdapter?
    
    open var retrier: RequestRetrier? {
        get { return delegate.retrier }
        set { delegate.retrier = newValue }
    }
    
    
    /// The background completion hander closure provided by the UIApplicationDelegate
    /// `application:HandlerEventsForBackgroundURLSession:completionHandler:` method. By setting the background completion handler, the SessionDelegate `sessionDidFinishEvnetsForBackgroundURLSession` closure implementation will automatically call the handler.
    /// If you need to handle your own events before the handler is called, then you need to override the SessionDelegate `sessionDidFinishEventsForBackgroundURLSession` and manually call the handler when finished.
    /// `nil` by default.
    open var backgroundCompletionHandler: (() -> Void)?
    
    let queue = DispatchQueue(label: "org.alamofire.session-manager." + UUID().uuidString)
    
    //MARK: - Lifecycle
    
    /// Creates an instance with the specified `configuration`, `delegate` and `serverTrustPolicyManager`.
    ///
    /// - Parameters:
    ///   - configuration:            The configuration used to construct the managed session.
    ///   - delegate:                 The delegate used when initializing the session. `SessionDelegate()` by default.
    ///   - serverTrustPolicyManager: The server trust policy manager to use for evaluating all server trust challenges. `nil` by default.
    public init(configuration: URLSessionConfiguration = URLSessionConfiguration.default, delegate: SessionDelegate = SessionDelegate(), serverTrustPolicyManager: ServerTrustPolicyManager? = nil) {
        self.delegate = delegate
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        commonInit(serverTrustPolicyManager: serverTrustPolicyManager)
    }
    
    /// Creates an instance with the specified `session`, `delegate` and `serverTrustPolicyManager`.
    ///
    /// - Parameters:
    ///   - session:                  The URL session.
    ///   - delegate:                 The delegate of the URL session. Must equal the URL session's delegate.
    ///   - serverTrustPolicyManager: The server trust policy manager to use for evaluating all server trust challenges. `nil` by default.
    public init?(session: URLSession, delegate: SessionDelegate, serverTrustPolicyManager: ServerTrustPolicyManager? = nil) {
        guard delegate === session.delegate else { return nil }
        
        self.delegate = delegate
        self.session = session
        
        commonInit(serverTrustPolicyManager: serverTrustPolicyManager)
    }
    
    public func commonInit(serverTrustPolicyManager: ServerTrustPolicyManager?) {
        session.serverTrustPolicyManager = serverTrustPolicyManager
        
        delegate.sessionManager = self
        delegate.sessionDidFinishEvemtsForBackgroundURLSession = { [weak self] session in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async { strongSelf.backgroundCompletionHandler?() }
        }
    }
    
    deinit {
        session.invalidateAndCancel()
    }
    
    open func request(_ url: URLConvertible,
                      method: HTTPMethod = .get,
                      parameters: Parameters? = nil,
                      encoding: ParametersEncoding = URLEncoding.default,
                      headers: HTTPHeaders? = nil) -> DataRequest {
        
        var originalRequest: URLRequest?
        
        do {
            originalRequest = try URLRequest(url: url, method: method, headers: headers)
            let encodedURLRequest = try encoding.encode(originalRequest!, with: parameters)
            return request(encodedURLRequest)
        } catch {
            return request(originalRequest, failedWith: error)
        }
    }
    
    open func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
        
        var originalRequest: URLRequest?
        
        do {
            originalRequest = try urlRequest.asURLRequest()
            let originalTask = DataRequest.Requestable(urlRequest: originalRequest!)
            
            let task = try originalTask.task(session: session, adapter: adapter, queue: queue)
            let request = DataRequest(session: session, requestTask: .data(originalTask, task))
            
            delegate[task] = request
            
            if startRequestsImmediately { request.resume() }
            
            return request
        } catch {
            return request(originalRequest, failedWith: error)
        }
    }
    
    private func request(_ urlRequest: URLRequest?,
                         failedWith error: Error) -> DataRequest {
        var requestTask: Request.RequestTask = .data(nil, nil)
        
        if let urlRequest = urlRequest {
            let originalTask = DataRequest.Requestable(urlRequest: urlRequest)
            requestTask = .data(originalTask, nil)
        }
        
        let underlyingError = error.underlyingAdaptError ?? error
        let request = DataRequest(session: session, requestTask: requestTask, error: underlyingError)
        
        if let retrier = retrier, error is AdaptError {
            allowRetrier(retrier, toRetry: request, with: underlyingError)
        } else {
            if startRequestsImmediately { request.resume() }
        }
        
        return request
    }
    
    // MARK; - Download Request.
    
    
    
    // MARK: - Internal - Retry Request.
    
    func retry(_ request: Request) -> Bool {
        guard let originalTask = request.originalTask else { return false }
        
        do {
            let task = try originalTask.task(session: session, adapter: adapter, queue: queue)
            
            request.delegate.task = task // resets all task delegate data.
            
            request.retryCount += 1
            request.startTime = CFAbsoluteTimeGetCurrent()
            request.endTime = nil
            
            task.resume()
            
            return true
        } catch {
            request.delegate.error = error.underlyingAdaptError ?? error
            return false
        }
    }
    
    private func allowRetrier(_ retrier: RequestRetrier, toRetry request: Request, with error: Error) {
        DispatchQueue.utility.async { [weak self] in
            guard let strongSelf = self else { return }
            
            retrier.should(strongSelf, retry: request, with: error) { shouldRetry, timeDelay in
                guard let strongSelf = self else { return }
                guard shouldRetry else {
                    if strongSelf.startRequestsImmediately { request.resume() }
                    return
                }
                
                DispatchQueue.utility.after(timeDelay) {
                    guard let strongSelf = self else { return }
                    
                    let retrySucceeded = strongSelf.retry(request)
                    if retrySucceeded, let task = request.task {
                        strongSelf.delegate[task] = request
                    } else {
                        if strongSelf.startRequestsImmediately { request.resume() }
                    }
                }
            }
        }
    }
}
