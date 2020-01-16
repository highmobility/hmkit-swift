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
//  HMTelematicsCommandError.swift
//  HMKit
//
//  Created by Mikk Rätsep on 24.10.19.
//

import Foundation


public struct HMTelematicsCommandError: Error, CustomStringConvertible {

    public enum Origin: UInt8 {
        case server     = 0x00
        case receiver   = 0x01
        case container  = 0x36
    }

    public enum Reason: UInt8 {
        case internalError  = 0x01
        case invalidData    = 0x04
        case invalidHMAC    = 0x08
        case timeout        = 0x09
    }

    public let origin: Origin
    public let reason: Reason


    init(bytes: [UInt8]) throws {
        guard bytes.count == 3,
            bytes.first == 0x02 else {
                throw HMProtocolError.invalidData
        }

        guard let origin = Origin(rawValue: bytes[1]),
            let reason = Reason(rawValue: bytes[2]) else {
                throw HMProtocolError.invalidData
        }

        self.origin = origin
        self.reason = reason
    }


    // MARK: CustomStringConvertible

    public var description: String {
        "\(Self.self)(origin: .\(origin), reason: .\(reason))"
    }
}
