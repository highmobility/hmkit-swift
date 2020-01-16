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
//  HMGetDeviceCertificateCommandRequest.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/02/2019.
//

import Foundation
import HMCryptoKit
import Security


class HMGetDeviceCertificateCommandRequest: HMCommandRequest {

    var nonce: [UInt8] {
        return bytes[1..<10].bytes
    }


    convenience init(privateKey: KeyType) throws {
        let header = HMCommandRequest.header(forCommand: .getDeviceCert)
        let nonce = [UInt8](repeating: 0x00, count: 9)
        let signature = try HMCryptoKit.signature(message: nonce, privateKey: privateKey)

        try self.init(bytes: header + nonce + signature)
    }


    // MARK: HMCommandRequest

    override init(bytes: [UInt8]) throws {
        guard bytes.count == 74 else {
            throw HMProtocolError.invalidData
        }

        try super.init(bytes: bytes)
    }
}

extension HMGetDeviceCertificateCommandRequest: HMVerifiableCommand {

    typealias KeyType = SecKey


    var message: [UInt8] {
        return nonce
    }

    var signature: [UInt8] {
        return bytes[10..<74].bytes
    }


    func isSignatureValid(forKey key: KeyType) throws -> Bool {
        // Check if the nonce is from the vehicle (zeroes) or the server
        guard nonce == [UInt8](repeating: 0x00, count: 9) else {
            // Server signed it and it'll be checked with the CA's public key
            return try HMCryptoKit.verify(signature: signature, message: message, publicKey: key)
        }

        // Find the vehicle's public key from stored certificates
        return try HMStorage.shared.certificates.contains {
            let key = try HMCryptoKit.publicKey(binary: $0.gainingPublicKey)

            do {
                return try HMCryptoKit.verify(signature: signature, message: nonce, publicKey: key)
            }
            catch let error as HMCryptoKitError {
                // Handles the "invalid signature" error (which is expected on all but 1 certificate)
                guard case .secKeyError(let secKeyError as Error) = error  else {
                    throw error
                }

                let nsError = secKeyError as NSError

                guard nsError.domain == NSOSStatusErrorDomain,
                    nsError.code == Int(errSecVerifyFailed) else {
                        throw error
                }

                return false
            }
            catch {
                throw error
            }
        }
    }
}
