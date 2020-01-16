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
//  HMTelematicsCommandResponse.swift
//  HMKit
//
//  Created by Mikk Rätsep on 12/05/2019.
//

import Foundation


struct HMTelematicsCommandResponse: Decodable {

    let container: HMTelematicsContainer
    let message: String
    let status: HMTelematicsCommandStatus


    // MARK: CodingKey

    enum Key: String, CodingKey {
        case message
        case data = "response_data"
        case status
    }


    // MARK: Decodable

    init(from decoder: Decoder) throws {
        let decodeContainer = try decoder.container(keyedBy: Key.self)
        let dataB64 = try decodeContainer.decode(String.self, forKey: .data)
        let statusStr = try decodeContainer.decode(String.self, forKey: .status)

        guard let data = Data(base64Encoded: dataB64),
            let cmdStatus = HMTelematicsCommandStatus(rawValue: statusStr) else {
                throw HMTelematicsError.invalidData
        }

        let cleanedBytes = HMParser.stripProtocolBytes(from: data.bytes)

        do {
            container = try HMTelematicsContainer(bytes: cleanedBytes)
            message = try decodeContainer.decode(String.self, forKey: .message)
            status = cmdStatus

            log("📜 \(type(of: self))",
                "container: \(container)",
                "message: \(message)",
                "status: \(cmdStatus)",
                types: [.telematics, .maidu])
        }
        catch {
            log("📜 \(type(of: self))",
                "bytes: \(cleanedBytes.hex)",
                "status: \(cmdStatus)",
                "error: \(error)",
                types: [.telematics, .maidu, .error])

            throw error
        }
    }
}

extension HMTelematicsCommandResponse: HMTelematicsResponse {

}
