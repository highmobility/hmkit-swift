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
//  HMDeviceCertificate.swift
//  HMKit
//
//  Created by Mikk Rätsep on 26/10/2017.
//

import Foundation
import HMCryptoKit


public class HMDeviceCertificate: Codable {

    public let bytes: [UInt8]
    public let version: Version


    public var appIdentifier: [UInt8] {
        switch version {
        case .basic:    return bytes[4..<16].bytes
        }
    }

    public var issuer: [UInt8] {
        switch version {
        case .basic:    return bytes[0..<4].bytes
        }
    }

    public var publicKey: [UInt8] {
        switch version {
        case .basic:    return bytes[25..<89].bytes
        }
    }

    public var serial: [UInt8] {
        switch version {
        case .basic:    return bytes[16..<25].bytes
        }
    }


    // MARK: Init

    public init?<C: Collection>(binary: C) where C.Element == UInt8 {
        if binary.isVersion(.deviceCertificate(.basic)) {
            bytes = binary.bytes
            version = .basic
        }
        else {
            return nil
        }
    }

    public convenience init?(base64Encoded string: String) {
        guard let data = Data(base64Encoded: string) else {
            return nil
        }

        self.init(binary: data)
    }

    public convenience init?<C: Collection>(appIdentifier: C, issuer: C, publicKey: C, serial: C, signature: C, version: Version) where C.Element == UInt8 {
        guard issuer.count == 4 else {
            return nil
        }

        guard appIdentifier.count == 12 else {
            return nil
        }

        guard serial.count == 9 else {
            return nil
        }

        guard publicKey.count == 64 else {
            return nil
        }

        guard signature.count == kSignatureSize else {
            return nil
        }

        // Everything seems to check out
        var bytes: [UInt8]

        // Combine version-specific bytes
        switch version {
        case .basic:
            bytes = issuer.bytes + appIdentifier.bytes + serial.bytes + publicKey.bytes
        }

        // Add the signature after permissions as well
        bytes += signature.bytes

        self.init(binary: bytes)
    }
}

extension HMDeviceCertificate: Equatable {

    public static func ==(lhs: HMDeviceCertificate, rhs: HMDeviceCertificate) -> Bool {
        return lhs.bytes == rhs.bytes
    }
}

extension HMDeviceCertificate: HMSigned {
}

extension HMDeviceCertificate {

    var publicKeyECKey: SecKey? {
        return try? HMCryptoKit.publicKey(binary: publicKey)
    }
}
