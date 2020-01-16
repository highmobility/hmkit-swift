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
//  HMRevokeCommandResponse.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/02/2019.
//

import Foundation


class HMRevokeCommandResponse: HMCommandResponse {

    var responseData: [UInt8] {
        return bytes[4...].bytes
    }


    convenience init(responseBytes bytes: [UInt8]) throws {
        let header = HMCommandResponse.header(forCommand: .revoke)
        let sizeBytes = [(bytes.count >> 8).uint8, bytes.count.uint8]

        try self.init(bytes: header + sizeBytes + bytes)
    }


    // MARK: HMCommandResponse

    override init(bytes: [UInt8]) throws {
        guard bytes.count >= 4 else {
            throw HMProtocolError.invalidData
        }

        let dataSize = (bytes[2].int << 8) + bytes[3].int

        guard bytes.count == (4 + dataSize) else {
            throw HMProtocolError.invalidData
        }

        try super.init(bytes: bytes)
    }
}
