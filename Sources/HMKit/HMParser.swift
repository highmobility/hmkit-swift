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
//  HMParser.swift
//  HMKit
//
//  Created by Mikk Rätsep on 01/11/2018.
//

import Foundation


struct HMParser {
    
    var delegate: HMParserDelegate? = nil

    private var outgoingPackageBuffer: [UInt8] = []
    private var incomingPackageBuffer: [UInt8] = []

    private var outgoingAcceptNextByte = false
    private var incomingAcceptNextByte = false


    // MARK: Type Methods

    /// Add protocol-bytes to the input.
    ///
    /// - Parameter bytes: The data to handle.
    /// - Returns: Protocol formatted bytes.
    static func protocolFormattedBytes(from bytes: [UInt8]) -> [UInt8] {
        var protocolledData = [HMProtocolBytes.start.rawValue]

        bytes.forEach {
            // Escapes the special-bytes
            if ($0 == HMProtocolBytes.start.rawValue) ||
                ($0 == HMProtocolBytes.escape.rawValue) ||
                ($0 == HMProtocolBytes.end.rawValue) {
                protocolledData.append(HMProtocolBytes.escape.rawValue)
            }

            protocolledData.append($0)
        }

        // End with the end-byte
        protocolledData.append(HMProtocolBytes.end.rawValue)

        return protocolledData
    }

    static func stripProtocolBytes(from bytes: [UInt8]) -> [UInt8] {
        var buffer = [UInt8]()
        var acceptNextByte = false

        HMParser().parseIncomingBytes(bytes, buffer: &buffer, acceptNextByte: &acceptNextByte, isOutgoing: false, sendToDelegate: false)

        return buffer
    }


    // MARK: Methods

    /// Parses the received data, including all the protocol bytes.
    /// Returns full package if reached the end byte and stores the leftover bytes as iVar
    ///
    /// - Parameters:
    ///   - binary: The binary that will be parsed by handling the protocol specific bytes.
    ///   - characteristic: The characteristic's type.
    ///   - completePackageReceived: Block that's called when a *full/complete* command has been parsed.
    mutating func parseIncoming<C: Collection>(binary: C, characteristic: HMCharacteristic) where C.Element == UInt8 {
        switch characteristic {
        case .outgoingWrite:
            parseIncomingBytes(binary.bytes, buffer: &outgoingPackageBuffer, acceptNextByte: &outgoingAcceptNextByte, isOutgoing: true)

        case .incomingWrite:
            parseIncomingBytes(binary.bytes, buffer: &incomingPackageBuffer, acceptNextByte: &incomingAcceptNextByte, isOutgoing: false)

        default:
            return
        }
    }


    // MARK: Init

    init() {
        
    }
}

private extension HMParser {

    func parseIncomingBytes(_ bytes: [UInt8], buffer: inout [UInt8], acceptNextByte: inout Bool, isOutgoing: Bool, sendToDelegate: Bool = true) {
        // A simple loop that goes through all the bytes and picks out the protocol-ones
        for byte in bytes {
            if acceptNextByte {
                // Next byte can't be escaped
                acceptNextByte = false
            }
            else if byte == HMProtocolBytes.start.rawValue {
                // Start with a clean buffer
                buffer = []

                // Don't add the byte
                continue
            }
            else if byte == HMProtocolBytes.escape.rawValue {
                // Accept the next byte, even if it's "special"
                acceptNextByte = true

                // Don't add the byte
                continue
            }
            else if byte == HMProtocolBytes.end.rawValue {
                if sendToDelegate {
                    let completePackage = buffer

                    // Reset it for good measure
                    buffer = []

                    // Send the finished buffer away
                    delegate?.parser(self, didReadCompletePackage: completePackage, isOutgoing: isOutgoing)

                    // Don't add the byte
                    continue
                }
                else {
                    // Just end without cleaning the buffer (it gets used elsewhere)
                    return
                }
            }

            // Add the byte to the buffer
            buffer.append(byte)
        }
    }
}
