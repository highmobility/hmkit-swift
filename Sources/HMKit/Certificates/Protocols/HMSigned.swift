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
//  HMSigned.swift
//  HMKit
//
//  Created by Mikk Rätsep on 24/10/2017.
//

import Foundation
import HMCryptoKit


/// Constant for Signature's size
let kSignatureSize = 64


/// A type that is signed with a signature and it can be verified.
public protocol HMSigned: HMBytesGettable {

    var signature: [UInt8] { get }


    func isSignatureValid(forPublicKey publicKey: SecKey) -> Bool
}

extension HMSigned {

    public var signature: [UInt8] {
        return bytes.suffix(kSignatureSize).bytes
    }


    public func isSignatureValid(forPublicKey publicKey: SecKey) -> Bool {
        guard signature.count == kSignatureSize else {
            return false
        }

        let message = bytes.prefix(upTo: (bytes.count - kSignatureSize))

        return (try? HMCryptoKit.verify(signature: signature, message: message.bytes, publicKey: publicKey)) ?? false
    }
}
