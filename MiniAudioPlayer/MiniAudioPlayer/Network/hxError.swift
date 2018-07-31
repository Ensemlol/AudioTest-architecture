//
//  hxError.swift
//  MiniAudioPlayer
//
//  Created by Ensem on 2018/7/31.
//  Copyright © 2018年 Ensem. All rights reserved.
//

import Foundation

public enum hxError: Error {
    
    /// The underlying reason the parameter encoding error occurred.
    ///
    /// - missingURL:                 The URL request did not have a URL to encode.
    ///
    /// - jsonEncodingFailed:         JSON serialization failed with an underlying system error during the encoding process.
    ///
    /// - propertyListEncodingFailed: Property list serialization failed with an underlying system error during encoding process.
    public enum ParameterEncodingFailureReason {
        case missingURL
        case jsonEncodingFailed(error: Error)
        case propertyListEncodingFailed(error: Error)
    }
    
    /// The underlying reason the multipart encoding error occirred.
    public enum MultipartEncodingFailureReason {
        case bodyPartURLInvalid(url: URL)
        case bodyPartFilenameInvalid(in: URL)
        case bodyPartFileNotReachable(at: URL)
        case bodyPartFileNotReachableWithError(atURL: URL, error: Error)
        case bodyPartFileIsDirectory(at: URL)
        case bodyPartFileSizeNotAvailable(at: URL)
        case bodyPartFileSizeQueryFailedWithError(forURL: URL, error: Error)
        case bodyPartInputStreamCreationFailed(for: URL)
        
        case outputStreamCreationFailed(for: URL)
        case outputStreamFileAlreadyExists(at: URL)
        case outputStreamURLInvalid(url: URL)
        case outputStreamWriteFailed(error: Error)
        
        case inputStreamReadFailed(error: Error)
    }
    
    public enum ResponseValidationFailureReason {
        case dataFileNil
        case dataFileReadFailed(at: URL)
        case missingContentType(acceptableContentTypes: [String])
        case unacceptableContentType(acceptableContentTypes: [String], responseContentType: String)
        case unacceptableStatusCode(code: Int)
    }
    
    public enum ResponseSerializationFailedReason {
        case inputDataNil
        case inputDataNilOrZeroLength
        case inputFileNil
        case inputFileReadFailed(at: URL)
        case stringSerializationFailed(encoding: String.Encoding)
        case jsonSerializationFailed(error: Error)
        case propertyListSerializationFailed(error: Error)
    }
    
    case invalidURL(url: URLConvertible)
    case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
    case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
    case responseValidationFailed(reason: ResponseValidationFailureReason)
    case responseSerializationFailed(reason: ResponseSerializationFailedReason)
}

// MARK: - AdaptError
struct AdaptError: Error {
    let error: Error
}
