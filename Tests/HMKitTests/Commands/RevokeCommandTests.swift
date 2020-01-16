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
//  RevokeCommandTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 14/06/2018.
//

@testable import HMKit

import HMUtilities
import XCTest

/*
 0x38 Revoke – Needs Authentication before using

 Req:
 Data[2 to 11]: Serial number ( 9 bytes )
 Data[11 to 43]: HMAC ( Req + serial number ) ( 32 bytes )

 Ack:
 Data[3]: Response data size
 Data[4]: Response data size
 Data[5 to A]: Response data

 Error:
 0x01 - Internal error
 0x04 - Invalid data
 0x07 - Unauthorised
 0x08 - Invalid HMAC
 */

class RevokeCommandTests: XCTestCase {

    static var allTests = [("testResponse", testResponse),
                           ("testRequest", testRequest)]


    // MARK: XCTestCase

    func testResponse() throws {
        let bytes: [UInt8] = [0x01, 0x38, 0x00, 0x02, 0xAA, 0xBB]
        let response = try HMRevokeCommandResponse(bytes: bytes)

        XCTAssertEqual(response.responseData, "AABB".hexBytes)
    }

    func testRequest() throws {
        let bytes = "38483364301D2D037A011C06F8799B574157538D2B8806D1C2542D13105F85D882C8706AA99D1D142A12".hexBytes
        let request = try HMRevokeCommandRequest(bytes: bytes)

        XCTAssertEqual(request.signature, "1C06F8799B574157538D2B8806D1C2542D13105F85D882C8706AA99D1D142A12".hexBytes)
        XCTAssertEqual(request.serial, "483364301D2D037A01".hexBytes)

        // Check the HMAC
        XCTAssertTrue(try request.isSignatureValid(forKey: "F8084E6A8D3587355374445DC052C3CAE32AB7EF3765A8BF2DD2947DFB0A2440".hexBytes), "Invalid HMAC")
    }
}
