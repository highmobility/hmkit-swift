//
//  The MIT License
//
//  Copyright (c) 2014- High-Mobility GmbH (https://high-mobility.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//
//  HMProtocolError.swift
//  HMKit
//
//  Created by Mikk Rätsep on 01/11/2018.
//

import Foundation


public enum HMProtocolError: UInt8, Error {

    case internalError      = 0x01
    case commandEmpty       = 0x02
    case commandUnknown     = 0x03
    case invalidData        = 0x04
    case storageFull        = 0x05
    case invalidSignature   = 0x06
    case unauthorised       = 0x07
    case invalidHMAC        = 0x08
    case timeout            = 0x09
    case notAccepted        = 0x10


    // MARK: iVars

    var linkError: HMLinkError {
        switch self {
        case .storageFull:      return HMLinkError.storageFull
        case .timeout:          return HMLinkError.timeOut
        case .unauthorised:     return HMLinkError.unauthorised
        case .invalidSignature,
             .invalidHMAC:      return HMLinkError.invalidSignature
        default:                return HMLinkError.internalError
        }
    }
}
