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
//  HMBytesAndVersionCodable.swift
//  HMKit
//
//  Created by Mikk Rätsep on 27/10/2017.
//

import Foundation


private enum BytesAndVersionCodingKeys: CodingKey {
    case value
    case bytes
}


protocol HMBytesAndVersionCodable: HMValueGettable {

    // Not using HMBytesGettable (originally meant for certificates), because it's a public one.
    // And don't want to make XXX.Version.bytes accessible from outside.
    var bytes: [UInt8] { get }


    init?(value: UInt8, bytes: [UInt8])
}

extension HMBytesAndVersionCodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: BytesAndVersionCodingKeys.self)

        try container.encode(value ?? UInt8(0), forKey: .value)
        try container.encode(bytes, forKey: .bytes)
    }


    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: BytesAndVersionCodingKeys.self)
        let value = try container.decode(UInt8.self, forKey: .value)
        let bytes = try container.decode([UInt8].self, forKey: .bytes)

        guard let myself = Self(value: value, bytes: bytes) else {
            throw HMProtocolError.invalidData
        }

        self = myself
    }
}

extension HMBytesAndVersionCodable {

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.bytes == rhs.bytes
    }
}
