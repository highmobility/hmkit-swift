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
//  HMTelematicsCommandRequest.swift
//  HMKit
//
//  Created by Mikk Rätsep on 12/05/2019.
//

import Foundation


struct HMTelematicsCommandRequest: Encodable, HMTelematicsRequest {

    let dataBytes: [UInt8]
    let issuer: [UInt8]
    let serial: [UInt8]


    init(command: [UInt8], contentType: HMContainerContentType, nonce: [UInt8], requestID: [UInt8], serial: [UInt8], accessCertificate: HMAccessCertificate) throws {
        guard case .one(let issuer) = accessCertificate.version else {
            throw HMTelematicsError.invalidData
        }

        // Use the correct version
        let version: HMTelematicsContainerVersion

        switch HMLocalDevice.shared.configuration.containerVersion {
        case .one:  version = .one
        case .two:  version = .two(contentType: contentType, requestID: requestID, receiverSerial: serial)
        }

        // Make the container
        let container = try HMTelematicsContainer(command: command,
                                                  nonce: nonce,
                                                  serial: serial,
                                                  version: version)

        self.dataBytes = HMParser.protocolFormattedBytes(from: container.bytes)
        self.issuer = issuer
        self.serial = serial

        log("📜 \(type(of: self))",
            "command: \(command.hex)",
            "container: \(container.bytes.hex)",
            "issuer: \(issuer.hex)",
            "serial: \(serial.hex)",
            "nonce: \(nonce.hex)",
            "version: \(version)",
            types: [.telematics, .maidu])
    }


    // MARK: CodingKey

    enum Keys: String, CodingKey {
        case data
        case issuer
        case serial = "serial_number"
    }


    // MARK: Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)

        try container.encode(dataBytes.data.base64EncodedString(), forKey: .data)
        try container.encode(issuer.hex.uppercased(), forKey: .issuer)
        try container.encode(serial.hex.uppercased(), forKey: .serial)
    }


    // MARK: HMTelematicsRequest

    typealias Response = HMTelematicsCommandResponse


    var endpoint: HMTelematicsAPI.Endpoint = .commands
}
