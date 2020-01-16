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
//  HMAccessCertificate.swift
//  HMKit
//
//  Created by Mikk Rätsep on 26/10/2017.
//

import Foundation
import HMCryptoKit
import HMUtilities


public class HMAccessCertificate: Codable {

    public let bytes: [UInt8]
    public let validity: HMPeriod
    public let version: Version


    public var gainingPublicKey: [UInt8] {
        switch version {
        case .basic:    return bytes[9..<73].bytes
        case .one:      return bytes[23..<87].bytes
        }
    }

    public var gainingSerial: [UInt8] {
        switch version {
        case .basic:    return bytes[0..<9].bytes
        case .one:      return bytes[14..<23].bytes
        }
    }

    public var providingSerial: [UInt8] {
        switch version {
        case .basic:    return bytes[73..<82].bytes
        case .one:      return bytes[5..<14].bytes
        }
    }

    public var permissions: [UInt8]? {
        let size = bytes[version.permissionIndex].int

        guard (0...16).contains(size) else {
            return nil
        }

        let startIdx = version.permissionIndex + 1

        return bytes[startIdx..<(startIdx + size)].bytes
    }


    // MARK: Init

    public init?<C: Collection>(binary: C) where C.Element == UInt8 {
        if binary.isVersion(.accessCertificate(.basic)) {
            guard let dates = HMPeriod(from: binary.bytes[82..<92]) else {
                return nil
            }

            bytes = binary.bytes
            validity = dates
            version = .basic
        }
        else if binary.isVersion(.accessCertificate(.one_empty)) {
            guard let dates = HMPeriod(from: binary.bytes[87..<97]) else {
                return nil
            }

            let issuer = binary.bytes[1..<5].bytes

            bytes = binary.bytes
            validity = dates
            version = .one(issuer: issuer)
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

    public convenience init?<C: Collection>(gainingSerial: C, gainingPublicKey: C, providingSerial: C, signature: C, validity: HMPeriod, version: Version, permissions: C? = nil) where C.Element == UInt8 {
        guard gainingSerial.count == 9 else {
            return nil
        }

        guard gainingPublicKey.count == 64 else {
            return nil
        }

        guard providingSerial.count == 9 else {
            return nil
        }

        guard signature.count == kSignatureSize else {
            return nil
        }

        guard let dateBytes = validity.hmCustomBinary else {
            return nil
        }

        // Everything seems to check out
        var bytes: [UInt8]

        // Combine version-specific bytes
        switch version {
        case .basic:
            bytes = gainingSerial.bytes + gainingPublicKey.bytes + providingSerial.bytes + dateBytes

        case .one(let issuer):
            guard let versionValue = version.value else {
                return nil
            }

            guard issuer.count == 4 else {
                return nil
            }

            bytes = [versionValue] + issuer + providingSerial.bytes + gainingSerial.bytes + gainingPublicKey.bytes + dateBytes
        }

        // Handle permissions
        if let permissions = permissions {
            guard (0...16).contains(permissions.count) else {
                return nil
            }

            bytes += [permissions.count.uint8] + permissions.bytes
        }
        else {
            bytes += [0x00]
        }

        // Add the signature after permissions as well
        bytes += signature.bytes

        self.init(binary: bytes)
    }
}

public extension HMAccessCertificate {

    var isValidNow: Bool {
        return isValid(on: Date())
    }


    func isValid(on date: Date) -> Bool {
        return validity.isValid(on: Date())
    }
}

extension HMAccessCertificate: Equatable {

    public static func ==(lhs: HMAccessCertificate, rhs: HMAccessCertificate) -> Bool {
        return lhs.bytes == rhs.bytes
    }
}

extension HMAccessCertificate: HMSimilar {

    public static func ~=(lhs: HMAccessCertificate, rhs: HMAccessCertificate) -> Bool {
        return (lhs.gainingSerial == rhs.gainingSerial) &&
            (lhs.gainingPublicKey == rhs.gainingPublicKey) &&
            (lhs.providingSerial == rhs.providingSerial)
    }
}

extension HMAccessCertificate: HMSigned {

}

extension HMAccessCertificate {

    var gainingPublicKeyECKey: SecKey? {
        return try? HMCryptoKit.publicKey(binary: gainingPublicKey)
    }
}
