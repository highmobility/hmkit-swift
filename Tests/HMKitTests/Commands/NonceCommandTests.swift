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
//  NonceCommandTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 14/06/2018.
//

@testable import HMKit

import HMUtilities
import XCTest

/*
 0x30 Get Nonce

 Req:
 Empty

 Ack:
 Data[3 to 12]: Nonce ( 9 bytes )

 Error:
 0x01 - Internal error : when generating nonce failes
 */

class NonceCommandTests: XCTestCase {

    static var allTests = [("testResponse", testResponse),
                           ("testRequest", testRequest)]


    // MARK: XCTestCase

    func testResponse() throws {
        let bytes = "013063804872C375843BB5".hexBytes
        let response = try HMGetNonceCommandResponse(bytes: bytes)
        
        XCTAssertEqual(response.nonce, "63804872C375843BB5".hexBytes)
    }

    func testRequest() {
        let bytes: [UInt8] = [0x30]

        XCTAssertEqual(try HMGetNonceCommandRequest().bytes, bytes)
    }
}
