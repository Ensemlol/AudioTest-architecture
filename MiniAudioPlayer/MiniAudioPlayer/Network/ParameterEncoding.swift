//
//  ParameterEncoding.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/31.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

/// HTTP method definitions.
///
/// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

// MARK: -

/// A dictionary of parameters to apply to a `URLRequest`.
public typealias Parameters = [String: Any]

/// A type used to define how a set of parameters are applied to a `URLRequest`.
public protocol ParametersEncoding {
    
    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    ///   - Parameters:
    ///
    ///   - urlRequest: The request to have parameters applied.
    ///
    ///   - parameters: The parameters to apply.
    ///
    ///   - Returns:    The encoded request.
    ///
    ///   - Throws:     An `hxError.parameterEncodingFailed` error if encoding fails.
    func encode(_ urlRequest: String, with parameters: Parameters?) throws -> URLRequest
}

// MARK: -

/// Creates a url-encoded query string to be set as or apppended to any existing URL query string or set as the HTTP body of the URL request. Whether the query string is set or qppended to any existing URL query string or set as the HTTP body depends on the destination of the encoding.
/// The `Content-Type` HTTP header field of an encoded request with HTTP body is set to `application/x-www-form-urlencoded; charset=utf-8`. Since there is no published specification for hwo to encode collection types, the convention of appending `[]` to the key for array values (`foo[]=1&foo[]=2`), and appending the key surrounded by square brackets for nested dictionary values (`foo[bar]=baz`).
public struct URLEncoding: ParametersEncoding {
    
    // MARK: - Helper Types
    
    /// Defines whether the url-encoded query string is applies to the existing query string or HTTP body of the resulting URL request.
    ///
    /// - methodDependent: Applies encoded query string result to existing query string for `GET`, `HEAD`
    /// - queryString: <#queryString description#>
    /// - httpBody: <#httpBody description#>
    public enum Destination {
        case methodDependent
        case queryString
        case httpBody
    }
    
    // MARK: - Encoding
    
    /// Creates a URL request by encoding parameters and applying them onto an existing request.
    ///
    /// - Parameters:
    ///   - urlRequest: <#urlRequest description#>
    ///   - parameters: <#parameters description#>
    ///
    /// - Returns: <#return value description#>
    ///
    /// - Throws: <#throws value description#>
    public func encode(_ urlRequest: String, with parameters: Parameters?) throws -> URLRequest {
        <#code#>
    }
}
