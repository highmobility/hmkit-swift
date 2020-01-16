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
//  HMCommandRequestFactory.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/02/2019.
//

import Foundation


struct HMCommandRequestFactory {

    static func create(fromBytes bytes: [UInt8]) throws -> HMCommandRequest {
        // Check if there's enough bytes
        guard bytes.count >= 1 else {
            throw HMProtocolError.invalidData
        }

        // Try to create the "type" of the request
        guard let command = HMProtocolCommand(rawValue: bytes[0]) else {
            throw HMProtocolError.invalidData
        }

        log("📜 \(command)", types: .command)

        // Initialise the correct request
        switch command {
        case .authenticate:     return try HMAuthenticateCommandRequest(bytes: bytes)
        case .authenticateDone: return try HMAuthenticateDoneCommandRequest(bytes: bytes)
        case .getAccessCert:    return try HMGetAccessCertificateCommandRequest(bytes: bytes)
        case .getDeviceCert:    return try HMGetDeviceCertificateCommandRequest(bytes: bytes)
        case .getNonce:         return try HMGetNonceCommandRequest(bytes: bytes)
        case .registerCert:     return try HMRegisterCertificateCommandRequest(bytes: bytes)
        case .revoke:           return try HMRevokeCommandRequest(bytes: bytes)
        case .secContainer:     return try HMSecureContainerCommandRequest(bytes: bytes)
        case .error:            return try HMErrorCommandRequest(bytes: bytes)
        }
    }
}
