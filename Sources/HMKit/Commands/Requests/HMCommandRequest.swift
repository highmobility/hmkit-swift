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
//  HMCommandRequest.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/02/2019.
//

import Foundation


class HMRequest {

    let bytes: [UInt8]


    // MARK: Init

    init(bytes: [UInt8]) throws {
        self.bytes = bytes
    }
}

class HMCommandRequest: HMRequest {

    let type: HMProtocolCommand

    var header: [UInt8] {
        return bytes[0..<1].bytes
    }


    // MARK: Methods

    class func header(forCommand command: HMProtocolCommand) -> [UInt8] {
        return [command.rawValue]
    }


    // MARK: Init

    /// Used by the -Factory
    override init(bytes: [UInt8]) throws {
        guard let type = HMProtocolCommand(rawValue: bytes[0]) else {
            throw HMProtocolError.invalidData
        }

        self.type = type

        try super.init(bytes: bytes)
    }
}
