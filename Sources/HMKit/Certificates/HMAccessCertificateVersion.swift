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
//  HMAccessCertificateVersion.swift
//  HMKit
//
//  Created by Mikk Rätsep on 26/10/2017.
//

import Foundation


public typealias HMAccessCertificateVersion = HMAccessCertificate.Version


extension HMAccessCertificate {

    public enum Version: HMBytesAndVersionCodable {
        case basic
        case one(issuer: [UInt8])


        static var one_empty: Version {
            return .one(issuer: [])
        }


        var minimumTotal: Int {
            return permissionIndex + 1 + kSignatureSize
        }

        var permissionIndex: Int {
            switch self {
            case .basic:    return 9 + 64 + 9 + 5 + 5
            case .one:      return 1 + 4 + 9 + 9 + 64 + 5 + 5
            }
        }


        // MARK: HMBytesAndVersionCodable

        public var value: UInt8? {
            switch self {
            case .basic:    return nil
            case .one:      return 1
            }
        }

        var bytes: [UInt8] {
            switch self {
            case .basic:
                return []

            case .one(let issuer):
                return issuer
            }
        }


        init?(value: UInt8, bytes: [UInt8]) {
            switch value {
            case 0:
                self = .basic

            case 1:
                guard bytes.count == 4 else {
                    return nil
                }

                self = .one(issuer: bytes)

            default:
                return nil
            }
        }
    }
}
