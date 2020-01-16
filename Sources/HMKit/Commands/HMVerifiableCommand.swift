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
//  HMVerifiableCommand.swift
//  HMKit
//
//  Created by Mikk Rätsep on 04/02/2019.
//

import Foundation
import HMCryptoKit


protocol HMKeyType {

    var bytes: [UInt8] { get }
    var count: Int { get }
}

extension SecKey: HMKeyType {

}

extension Array: HMKeyType where Element == UInt8 {

}


protocol HMVerifiableCommand {

    associatedtype KeyType: HMKeyType   // Not sure about this approach

    var message: [UInt8] { get }
    var signature: [UInt8] { get }

    func isSignatureValid(forKey key: KeyType) throws -> Bool
}

extension HMVerifiableCommand {

    func isSignatureValid(forKey key: KeyType) throws -> Bool {
        // TODO: Not happy with this approach
        if key.count == 32 {
            let sessionKey = key as! [UInt8]

            return try HMCryptoKit.verify(hmac: signature, message: message, key: sessionKey)
        }
        else if key.count == 64 {
            let publicKey = key as! SecKey

            return try HMCryptoKit.verify(signature: signature, message: message, publicKey: publicKey)
        }
        else {
            throw HMLinkError.internalError
        }
    }
}
