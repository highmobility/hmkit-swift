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
//  HMRegisterCertificateCommandResponse.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/02/2019.
//

import Foundation
import HMCryptoKit


class HMRegisterCertificateCommandResponse: HMCommandResponse {

    let publicKey: KeyType


    convenience init(publicKey: SecKey, privateKey: SecKey) throws {
        let header = HMCommandResponse.header(forCommand: .registerCert)
        let signature = try HMCryptoKit.signature(message: header + publicKey.bytes, privateKey: privateKey)

        try self.init(bytes: header + publicKey.bytes + signature)
    }


    // MARK: HMCommandResponse

    override init(bytes: [UInt8]) throws {
        guard bytes.count == 130 else {
            throw HMProtocolError.invalidData
        }

        self.publicKey = try HMCryptoKit.publicKey(binary: bytes[2..<66])

        // Verify the signature
        let signature = bytes[66..<130]
        let message = bytes[0..<66]

        guard try HMCryptoKit.verify(signature: signature, message: message, publicKey: publicKey) else {
            throw HMProtocolError.invalidSignature
        }

        try super.init(bytes: bytes)
    }
}

extension HMRegisterCertificateCommandResponse: HMVerifiableCommand {

    typealias KeyType = SecKey


    var message: [UInt8] {
        return bytes[0..<66].bytes
    }

    var signature: [UInt8] {
        return bytes[11..<75].bytes
    }
}
