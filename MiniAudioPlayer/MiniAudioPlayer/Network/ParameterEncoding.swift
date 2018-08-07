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
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest
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
    
    // MARK: - Properties
    
    /// Returns a `URLEncoding` instance.
    public static var `default`: URLEncoding { return URLEncoding() }
    
    public let destination: Destination
    
    // MARK: - Initizlization
    
    public init(destination: Destination = .methodDependent) {
        self.destination = destination
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
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        
        guard let parameters = parameters else { return urlRequest }
        
        if let method = HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET"), encodesParametersInURL(with: method) {
            guard let url = urlRequest.url else { throw hxError.parameterEncodingFailed(reason: .missingURL) }
            
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                let percentEncidedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncidedQuery
                urlRequest.url = urlComponents.url
            }
        } else {
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }
            
            urlRequest.httpBody = query(parameters).data(using: .utf8, allowLossyConversion: false)
        }
        
        return urlRequest
    }
    
    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                
            }
        }
        
        return components
    }
    
    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    private func encodesParametersInURL(with method: HTTPMethod) -> Bool {
        switch destination {
        case .queryString: return true
        case .httpBody: return false
        default:
            break
        }
        
        switch method {
        case .get, .head, .delete: return true
        default:
            return false
        }
    }
}

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}
