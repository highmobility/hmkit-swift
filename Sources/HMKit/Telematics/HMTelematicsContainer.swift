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
//  HMTelematicsContainer.swift
//  HMKit
//
//  Created by Mikk Rätsep on 03/06/2019.
//

import Foundation
import HMCryptoKit
import HMUtilities


class HMTelematicsContainer {

    let bytes: [UInt8]  // TODO: Is this really needed?
    let command: [UInt8]
    let version: HMTelematicsContainerVersion

    var contentType: HMContainerContentType {
        switch version {
        case .one:
            return .unknown

        case .two(let contentType, _, _):
            return contentType
        }
    }

    var requestID: [UInt8] {
        switch version {
        case .one:
            return []

        case .two(_, let requestID, _):
            return requestID
        }
    }


    // MARK: Init

    init(bytes: [UInt8]) throws {
        guard bytes.count >= 21 else {
            throw HMProtocolError.invalidData
        }

        let extractCommand: ((HMSessionKey, [UInt8]) throws -> [UInt8])
        let senderSerial: [UInt8]
        let isEncrypted: Bool
        let nonce: [UInt8]
        let payloadBytes: [UInt8]
        let version: HMTelematicsContainerVersion

        // Handle different versions
        switch bytes[0] {
        case 0x02:  /***   VERSION 2   ***/
            guard bytes.count >= 68 else {
                fallthrough
            }

            let requesIDSize = Int(UInt16(bytes: bytes[28...29])!)

            guard bytes.count >= (68 + requesIDSize) else {
                fallthrough
            }

            let commandSizeRange = (32 + requesIDSize)...(35 + requesIDSize)
            let commandSize = Int(UInt32(bytes: bytes[commandSizeRange])!)

            guard bytes.count == (68 + requesIDSize + commandSize) else {
                fallthrough
            }

            let contentType = HMContainerContentType(rawValue: bytes[31 + requesIDSize]) ?? .unknown
            let receiverSerial = bytes[10...18].bytes
            let requestID = bytes[30..<(30 + requesIDSize)].bytes

            senderSerial = bytes[1...9].bytes
            nonce = bytes[19...27].bytes
            isEncrypted = bytes[30 + requesIDSize] == 0x01
            payloadBytes = bytes[36..<(36 + commandSize)].bytes
            version = .two(contentType: contentType, requestID: requestID, receiverSerial: receiverSerial)

            extractCommand = { sessionKey, decryptedBytes in
                let hmac = bytes.suffix(32).bytes
                let message = bytes.prefix(upTo: bytes.count - 32).bytes

                guard try HMCryptoKit.verify(hmac: hmac, message: message, key: sessionKey.remoteSessionKey) else {
                    throw HMProtocolError.invalidHMAC
                }

                return decryptedBytes
            }

        default:    /***   VERSION 1   ***/
            senderSerial = bytes[0...8].bytes
            nonce = bytes[9...17].bytes
            isEncrypted = bytes[18] == 0x01
            payloadBytes = bytes.suffix(from: 19).bytes
            version = .one

            extractCommand = { sessionKey, decryptedBytes in
                let scc = try HMSecureContainerCommandRequest(bytes: decryptedBytes)

                guard try scc.isSignatureValid(forKey: sessionKey.remoteSessionKey) else {
                    throw HMProtocolError.invalidHMAC
                }

                return scc.command
            }
        }

        log("📦 \(type(of: self))",
            "bytes: \(bytes.hex)",
            "senderSerial: \(senderSerial.hex)",
            "isEncrypted: \(isEncrypted)",
            "nonce: \(nonce.hex)",
            "payload: \(payloadBytes.hex)",
            "version: \(version)",
            types: [.telematics, .maidu])

        // Check if the payload is an error
        if let error = try? HMTelematicsCommandError(bytes: payloadBytes) {
            throw HMTelematicsError.command(error)
        }

        // Common things
        guard let accessCertificate = HMStorage.shared.certificate(withGainingSerial: senderSerial),
            let privateKey = HMLocalDevice.shared.privateKey else {
                throw HMProtocolError.unauthorised
        }

        let decryptedBytes: [UInt8]
        let publicKey = try HMCryptoKit.publicKey(binary: accessCertificate.gainingPublicKey)
        let sessionKey = try HMSessionKey(privateKey: privateKey, otherPublicKey: publicKey, nonce: nonce)

        if isEncrypted {
            let iv = try HMCryptoKit.iv(nonce: nonce, transactionNonce: nonce)

            decryptedBytes = try HMCryptoKit.encryptDecrypt(message: payloadBytes, iv: iv, key: sessionKey.remoteSessionKey)
        }
        else {
            decryptedBytes = payloadBytes
        }

        self.bytes = bytes
        self.command = try extractCommand(sessionKey, decryptedBytes)
        self.version = version

        log("🔐 keys \(type(of: self))",
            "decryptedBytes: \(command.hex)",
            "publicKey: \(publicKey.hex)",
            "sessionKey: \(sessionKey.localSessionKey.hex)",
            types: [.telematics, .encryption])
    }

    init(command: [UInt8], nonce: [UInt8], serial: [UInt8], version: HMTelematicsContainerVersion) throws {
        // Common things
        guard let accessCertificate = HMStorage.shared.certificate(withGainingSerial: serial),
            let localSerial = HMLocalDevice.shared.serial,
            let privateKey = HMLocalDevice.shared.privateKey else {
                throw HMProtocolError.unauthorised
        }

        let encryptBytes: (HMSessionKey, [UInt8]) throws -> [UInt8] = { sessionKey, commandBytes in
            let iv = try HMCryptoKit.iv(nonce: nonce, transactionNonce: nonce)

            return try HMCryptoKit.encryptDecrypt(message: commandBytes, iv: iv, key: sessionKey.localSessionKey)
        }

        let publicKey = try HMCryptoKit.publicKey(binary: accessCertificate.gainingPublicKey)
        let sessionKey = try HMSessionKey(privateKey: privateKey, otherPublicKey: publicKey, nonce: nonce)
        var bytes: [UInt8] = []

        // Handle different versions
        switch version {
        case .one:
            let scc = try HMSecureContainerCommandRequest(command: command, sessionKey: sessionKey.localSessionKey, version: .one)
            let encryptedBytes = try encryptBytes(sessionKey, scc.bytes)

            guard encryptedBytes.count <= UInt16.max else {
                throw HMProtocolError.invalidData
            }

            bytes += localSerial
            bytes += nonce
            bytes += [0x01] // Only output encrypted commands (for now)
            bytes += encryptedBytes

        case .two(let contentType, let requestID, let receiverSerial):
            let encryptedBytes = try encryptBytes(sessionKey, command)

            guard receiverSerial == serial,
                requestID.count <= UInt16.max,
                encryptedBytes.count <= UInt32.max else {
                    throw HMProtocolError.invalidData
            }

            bytes += [0x02]
            bytes += localSerial
            bytes += receiverSerial // Same as .serial
            bytes += nonce
            bytes += UInt16(requestID.count).bytes
            bytes += requestID
            bytes += [0x01] // Only output encrypted commands (for now)
            bytes += [contentType.rawValue]
            bytes += UInt32(encryptedBytes.count).bytes
            bytes += encryptedBytes
            bytes += try HMCryptoKit.hmac(message: bytes, key: sessionKey.localSessionKey)
        }

        log("📦 \(type(of: self))",
            "command: \(command.hex)",
            "nonce: \(nonce.hex)",
            "serial: \(serial.hex)",
            "version: \(version)",
            "bytes: \(bytes.hex)",
            types: [.telematics, .maidu])

        log("🔐 keys \(type(of: self))",
            "publicKey: \(publicKey.hex)",
            "sessionKey: \(sessionKey.localSessionKey.hex)",
            types: [.telematics, .encryption])

        self.bytes = bytes
        self.command = command
        self.version = version
    }
}
