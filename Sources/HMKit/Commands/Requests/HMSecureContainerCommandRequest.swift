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
//  HMSecureContainerCommandRequest.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/02/2019.
//

import Foundation
import HMCryptoKit
import HMUtilities


class HMSecureContainerCommandRequest: HMCommandRequest {

    let version: HMSecureContainerCommandVersion

    var command: [UInt8] {
        let startIndex = version.commandStartIndex

        return bytes[startIndex..<(startIndex + commandSize)].bytes
    }

    var contentType: HMContainerContentType {
        switch version {
        case .one:
            return .unknown

        case .two(let contentType, _):
            return contentType
        }
    }

    var requestID: [UInt8] {
        switch version {
        case .one:
            return []

        case .two(_, let requestID):
            return requestID
        }
    }

    var requiresHMAC: Bool {
        return bytes[version.requiresHMACIndex] == 0x01
    }

    private let commandSize: Int


    convenience init(command: [UInt8], sessionKey: KeyType, version: HMSecureContainerCommandVersion) throws {
        var bytes = HMCommandRequest.header(forCommand: .secContainer)

        switch version {
        case .one:
            guard command.count <= UInt16.max else {
                throw HMProtocolError.invalidData
            }

            bytes += [0x01]
            bytes += UInt16(command.count).bytes
            bytes += command

        case .two(let contentType, let requestID):
            guard command.count <= UInt32.max,
                requestID.count <= UInt16.max else {
                    throw HMProtocolError.invalidData
            }

            bytes += [0x02, 0x01, contentType.rawValue]
            bytes += UInt32(command.count).bytes
            bytes += command
            bytes += UInt16(requestID.count).bytes
            bytes += requestID
        }

        bytes += try HMCryptoKit.hmac(message: bytes, key: sessionKey)

        try self.init(bytes: bytes)

        log("📦 \(type)",
            "command: \(command.hex)",
            "sessionKey: \(sessionKey.hex)",
            "version: \(version)",
            "combined bytes: \(self.bytes.hex)",
            types: [.bluetooth, .command, .maidu])
    }


    // MARK: HMCommandRequest

    override init(bytes: [UInt8]) throws {
        guard bytes.count >= 4 else {
            throw HMProtocolError.invalidData
        }

        switch bytes[1] {
        case 0x02:
            guard bytes.count >= 10 else {
                throw HMProtocolError.invalidData
            }

            commandSize = Int(UInt32(bytes: bytes[4...7])!)

            guard bytes.count >= (10 + commandSize) else {
                throw HMProtocolError.invalidData
            }

            let reqIDSizeRange = ((8 + commandSize)...(9 + commandSize))
            let reqIDSize = Int(UInt16(bytes: bytes[reqIDSizeRange])!)

            guard bytes.count == (10 + commandSize + reqIDSize + 32) else {
                throw HMProtocolError.invalidData
            }

            let contentType = HMContainerContentType(rawValue: bytes[3]) ?? .unknown
            let reqIDStartIdx = 10 + commandSize
            let reqID = bytes[reqIDStartIdx..<(reqIDStartIdx + reqIDSize)].bytes

            version = .two(contentType: contentType, requestID: reqID)

        default:
            commandSize = Int(UInt16(bytes: bytes[2...3])!)

            guard bytes.count == (4 + commandSize + 32) else {
                throw HMProtocolError.invalidData
            }

            version = .one
        }

        try super.init(bytes: bytes)

        log("📦 \(type)",
            "command: \(command.hex)",
            "version: \(version)",
            types: [.bluetooth, .command, .maidu])
    }
}

extension HMSecureContainerCommandRequest: HMVerifiableCommand {

    typealias KeyType = Array<UInt8>


    var message: [UInt8] {
        return bytes[..<(bytes.count - 32)].bytes
    }

    var signature: [UInt8] {
        return bytes.suffix(32).bytes
    }
}
