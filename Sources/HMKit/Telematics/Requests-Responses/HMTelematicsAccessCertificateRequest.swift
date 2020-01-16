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
//  HMTelematicsAccessCertificateRequest.swift
//  HMKit
//
//  Created by Mikk Rätsep on 10/05/2019.
//

import Foundation
import HMCryptoKit


struct HMTelematicsAccessCertificateRequest: Encodable, HMTelematicsRequest {

    let accessToken: String
    let serial: [UInt8]
    let signature: [UInt8]


    init(accessToken: String, serial: [UInt8], privateKey: SecKey) throws {
        guard let message = accessToken.data(using: .utf8) else {
            throw HMTelematicsError.invalidData
        }

        self.accessToken = accessToken
        self.serial = serial
        self.signature = try HMCryptoKit.signature(message: message, privateKey: privateKey)
    }


    // MARK: CodingKey

    enum Keys: String, CodingKey {
        case accessToken = "access_token"
        case serial = "serial_number"
        case signature
    }


    // MARK: Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)

        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(serial.hex.uppercased(), forKey: .serial)
        try container.encode(signature.data.base64EncodedString(), forKey: .signature)
    }


    // MARK: HMTelematicsRequest

    typealias Response = HMTelematicsAccessCertificateResponse


    var endpoint: HMTelematicsAPI.Endpoint = .accessCertificates
}
