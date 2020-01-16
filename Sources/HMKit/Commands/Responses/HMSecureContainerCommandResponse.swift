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
//  HMSecureContainerCommandResponse.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/02/2019.
//

import Foundation
import HMCryptoKit
import HMUtilities



class HMSecureContainerCommandResponse: HMCommandResponse {

    let version: HMSecureContainerCommandVersion

    var contentType: HMContainerContentType {
        switch version {
        case .one:
            return .unknown

        case .two(let contentType, _):
            return contentType
        }
    }

    var hmac: [UInt8]? {
        return hasHMAC ? bytes.suffix(32).bytes : nil
    }

    var response: [UInt8] {
        let startIndex = version.responseStartIndex

        return bytes[startIndex..<(startIndex + responseSize)].bytes
    }

    private let hasHMAC: Bool
    private var responseSize: Int


    convenience init(response: [UInt8], sessionKey: KeyType?, version: HMSecureContainerCommandVersion) throws {
        var bytes = HMCommandResponse.header(forCommand: .secContainer)

        switch version {
        case .one:
            guard response.count <= UInt16.max else {
                throw HMProtocolError.invalidData
            }

            bytes += UInt16(response.count).bytes
            bytes += response

        case .two(let contentType, let requestID):
            guard response.count <= UInt32.max,
                requestID.count <= UInt16.max else {
                    throw HMProtocolError.invalidData
            }

            bytes += [0x02, contentType.rawValue]
            bytes += UInt32(response.count).bytes
            bytes += response
            bytes += UInt16(requestID.count).bytes
            bytes += requestID
        }

        if let sessionKey = sessionKey {
            bytes += try HMCryptoKit.hmac(message: bytes, key: sessionKey)
        }

        try self.init(bytes: bytes)
    }


    // MARK: HMCommandResponse

    override init(bytes: [UInt8]) throws {
        guard bytes.count >= 4 else {
            throw HMProtocolError.invalidData
        }

        switch bytes[2] {
        case 0x02:
            guard bytes.count >= 10 else {
                fallthrough
            }

            responseSize = Int(UInt32(bytes: bytes[4...7])!)

            guard bytes.count >= (10 + responseSize) else {
                fallthrough
            }

            let reqIDSizeRange = ((8 + responseSize)...(9 + responseSize))
            let reqIDSize = Int(UInt16(bytes: bytes[reqIDSizeRange])!)
            let size = 10 + responseSize + reqIDSize

            guard [size, (size + 32)].contains(bytes.count) else {
                fallthrough
            }

            let contentType = HMContainerContentType(rawValue: bytes[3]) ?? .unknown
            let reqIDStartIdx = 10 + responseSize
            let reqID = bytes[reqIDStartIdx..<(reqIDStartIdx + reqIDSize)].bytes

            hasHMAC = bytes.count == (size + 32)
            version = .two(contentType: contentType, requestID: reqID)

        default:
            responseSize = Int(UInt16(bytes: bytes[2...3])!)

            let size = 4 + responseSize

            guard [size, (size + 32)].contains(bytes.count) else {
                throw HMProtocolError.invalidData
            }

            hasHMAC = bytes.count == (size + 32)
            version = .one
        }

        try super.init(bytes: bytes)
    }
}

extension HMSecureContainerCommandResponse: HMVerifiableCommand {

    typealias KeyType = Array<UInt8>


    var message: [UInt8] {
        guard hmac != nil else {
            return bytes
        }

        return bytes[..<(bytes.count - 32)].bytes
    }

    var signature: [UInt8] {
        return hmac ?? []
    }
}
