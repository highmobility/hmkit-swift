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
//  HMSessionKey.swift
//  HMKit
//
//  Created by Mikk Rätsep on 01/11/2018.
//

import Foundation
import HMCryptoKit


class HMSessionKey {

    typealias Key = [UInt8]
    typealias Nonce = [UInt8]


    // MARK: iVars

    private(set) var localSessionKey: Key
    private(set) var remoteSessionKey: Key
    private(set) var originalNonce: Nonce

    private var sharedKey: Key

    private var localNonce: Nonce
    private var remoteNonce: Nonce


    // MARK: Methods

    func encryptDecrypt(_ bytes: [UInt8], useLocalSessionKey useLocal: Bool) throws -> [UInt8] {
        let transactionNonce = useLocal ? localNonce : remoteNonce
        let key = useLocal ? localSessionKey : remoteSessionKey
        let iv = try HMCryptoKit.iv(nonce: originalNonce, transactionNonce: transactionNonce)

        return try HMCryptoKit.encryptDecrypt(message: bytes, iv: iv, key: key)
    }

    func incrementRemote() {
        updateValues(sessionKey: &remoteSessionKey, nonce: &remoteNonce, name: "remote")
    }

    func incrementLocal() {
        updateValues(sessionKey: &localSessionKey, nonce: &localNonce, name: "local")
    }


    // MARK: Init

    init(privateKey: SecKey, otherPublicKey: SecKey, nonce: Nonce) throws {
        sharedKey = try HMCryptoKit.sharedKey(privateKey: privateKey, publicKey: otherPublicKey)

        // Create the session key
        let sessionKey = try HMCryptoKit.hmac(message: nonce, key: sharedKey)

        // Set other vars
        localNonce = nonce
        remoteNonce = nonce
        originalNonce = nonce
        localSessionKey = sessionKey.bytes
        remoteSessionKey = sessionKey.bytes

        log("creating a SESSION KEY 🔑",
            "nonce: \(nonce.hex)",
            "sessionKey: \(sessionKey.hex)",
            "sharedKey: \(sharedKey.hex)",
            types: .encryption)
    }
}

private extension HMSessionKey {

    func increaseNonce(_ nonce: inout Nonce) {
        // Find the 1st sub-255 byte
        guard let idx = nonce.enumerated().first(where: { $0.element != 0xFF })?.offset else {
            return
        }

        // Increase it
        nonce[idx] += 1
    }

    func updateValues(sessionKey: inout Key, nonce: inout Nonce, name: String) {
        // 1. increase nonce
        increaseNonce(&nonce)

        // 2. update session key
        do {
            sessionKey = try HMCryptoKit.hmac(message: nonce, key: sharedKey)

            log("increment 🔼 \(name) nonce",
                "new: \(nonce.hex)",
                "original: \(originalNonce.hex)",
                types: .encryption)
        }
        catch {
            log("failed to increment \(name) nonce",
                "error: \(error)",
                types: [.error, .encryption])
        }
    }
}
