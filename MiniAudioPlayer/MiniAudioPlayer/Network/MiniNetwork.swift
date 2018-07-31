//
//  MiniNetwork.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/31.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

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
