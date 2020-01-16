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
//  HMCommandResponseFactory.swift
//  HMKit
//
//  Created by Mikk Rätsep on 04/02/2019.
//

import Foundation


struct HMCommandResponseFactory {

    static func create(fromBytes bytes: [UInt8]) throws -> HMCommandResponse {
        // Check if there's enough bytes
        guard bytes.count >= 2 else {
            throw HMProtocolError.invalidData
        }

        // Try to create the "types" of the response
        guard let responseType = HMCommandResponseType(rawValue: bytes[0]),
            let command = HMProtocolCommand(rawValue: bytes[1]) else {
                throw HMProtocolError.invalidData
        }

        // Check if the response is an ACK
        guard responseType == .ack else {
            // If not, then it must be an ERROR
            guard (responseType == .error) && (bytes.count >= 3),
                let error = HMProtocolError(rawValue: bytes[2]) else {
                    throw HMProtocolError.invalidData
            }

            // Throws an error that represents the ERROR
            throw HMCommandError(command: command, error: error)
        }

        // Initialise the correct response
        switch command {
        case .getNonce:         return try HMGetNonceCommandResponse(bytes: bytes)
        case .getDeviceCert:    return try HMGetDeviceCertificateCommandResponse(bytes: bytes)
        case .registerCert:     return try HMRegisterCertificateCommandResponse(bytes: bytes)
        case .getAccessCert:    return try HMGetAccessCertificateCommandResponse(bytes: bytes)
        case .authenticate:     return try HMAuthenticateCommandResponse(bytes: bytes)
        case .authenticateDone: return try HMAuthenticateDoneCommandResponse(bytes: bytes)
        case .secContainer:     return try HMSecureContainerCommandResponse(bytes: bytes)
        case .revoke:           return try HMRevokeCommandResponse(bytes: bytes)
        case .error:            return try HMErrorCommandResponse(bytes: bytes)
        }
    }
}
