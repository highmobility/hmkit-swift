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
//  HMGetAccessCertificateCommandRequest.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/02/2019.
//

import Foundation
import HMCryptoKit


class HMGetAccessCertificateCommandRequest: HMCommandRequest {

    var serial: [UInt8] {
        return bytes[1..<10].bytes
    }


    convenience init(serial: [UInt8], privateKey: KeyType) throws {
        let header = HMCommandRequest.header(forCommand: .getAccessCert)
        let signature = try HMCryptoKit.signature(message: header + serial, privateKey: privateKey)

        try self.init(bytes: header + serial + signature)
    }


    // MARK: HMCommandRequest

    override init(bytes: [UInt8]) throws {
        guard bytes.count == 74 else {
            throw HMProtocolError.invalidData
        }

        try super.init(bytes: bytes)
    }
}

extension HMGetAccessCertificateCommandRequest: HMVerifiableCommand {

    typealias KeyType = SecKey


    var message: [UInt8] {
        return header + serial
    }

    var signature: [UInt8] {
        return bytes[10..<74].bytes
    }
}
