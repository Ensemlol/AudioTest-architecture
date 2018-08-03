//
//  MiniNetwork.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/31.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

/// Types adapting the `URLConvertible` protocol can be used to construct URLs, which are then used to construct.
public protocol URLConvertible {
    
    /// Returns a URL that conforms to RFC 2396 or throws an `Error`.
    ///
    /// - Returns: A URL or throws an `Error`.
    ///
    /// - Throws:  An `Error` if the type cannot be converted to a `URL`.
    func asURL() throws -> URL
}

extension String: URLConvertible {
    
    /// Returns a URL if `self` represents a valid URL string that conforms to RFC 2396 or throws an `hxError`.
    ///
    /// - Returns: A URL or throws an `hxError`.
    ///
    /// - Throws:  An `hxError.invalidURL` if `self` is not a valid URL string.
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw hxError.invalidURL(url: self) }
        return url
    }
}

extension URL: URLConvertible {
    /// Returns self.
    public func asURL() throws -> URL {
        return self
    }
}

extension URLComponents: URLConvertible {
    
    /// Returns a URL if `url` is not nil, otherwise throws an `error`.
    ///
    /// - Returns: A URL or throws an Error.
    ///
    /// - Throws:  An `hxError.invalidURL` if `url` is `nil`
    public func asURL() throws -> URL {
        guard let url = url else { throw hxError.invalidURL(url: self) }
        return url
    }
}

// MARK: -

/// Types adapting the `URLRequestConvertible` protocol can be used to construct URL requests.
public protocol URLRequestConvertible {
    
    /// Returns a URL request or throws if an `Error` was encountered.
    ///
    /// - Returns: A URL request.
    ///
    /// - Throws:  An `Error` if the underlying `URLRequest` is `nil`.
    func asURLRequest() throws -> URLRequest
}

extension URLRequestConvertible {
    
    /// The URL request.
    public var urlRequest: URLRequest? { return try? asURLRequest() }
}

extension URLRequest: URLRequestConvertible {
    
    /// Returns a URL request or throws if an `Error` was encountered.
    public func asURLRequest() throws -> URLRequest { return self }
}

// MARK: -

extension URLRequest {
    
    /// Creates an instance with the specified `method`, `urlString` and `headers`.
    ///
    /// - Parameters:
    ///
    ///   - url:     The URL.
    ///   - method:  The HTTP method.
    ///   - headers: The HTTP headers. `nil` by default.
    ///
    /// - Throws: nil
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

// MARK: - Data Request

/// Creates a `DataRequest` using the default `SessionManager` to retrieve the contents of the specified `url`, `method`, `parameters`, `encoding` and `headers`.
///
/// - Parameters:
///   - url:        The URL.
///
///   - method:     The HTTP method. `get` by default.
///
///   - parameters: The parameters. `nil` by default.
///
///   - encoding:   The parameters encoding. `URLEncoding.default` by default.
///
///   - headers:    The HTTP headers. `nil` by default.
///
/// - Returns:      The created `DataRequest`.
@discardableResult
public func request(_ url: URLConvertible,
                    method: HTTPMethod = .get,
                    parameters: Parameters? = nil,
                    encoding: ParametersEncoding,
                    headers: HTTPHeaders? = nil)
        -> DataRequest {
    
        return SessionManager.default.request()
}
