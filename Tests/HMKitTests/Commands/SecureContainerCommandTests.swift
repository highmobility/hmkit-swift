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
//  SecureContainerCommandTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 14/06/2018.
//

@testable import HMKit

import HMUtilities
import XCTest

/*
 0x36 Secure command container - Needs Authentication before using. With this request you can send signed command to device and get signed response back

 Req:
 Data[2]: Requires HMAC Ack
 Data[3]: Command size
 Data[4]: Command size
 Data[5 to A]: Command
 Data[A to B]: HMAC ( command id + command size +  container command ) ( 32 bytes )

 Ack:
 Data[3]: Response size
 Data[4]: Response size
 Data[5 to A]: Response ( Contains full Ack response )
 Data[A to B]: HMAC ( Ack + response size + response ) ( 32 bytes )

 Error:
 0x01 - Internal error
 0x04 - Invalid data
 0x07 - Unauthorised
 0x08 - Invalid HMAC
 */

class SecureContainerCommandTests: XCTestCase {

    static var allTests = [("testResponse", testResponse),
                           ("testRequest", testRequest)]


    // MARK: XCTestCase

    func testResponse() throws {
        let bytes = "013600007D3BFC6BE25A497C313209EB92E36E64C92F15267D712D33CBAA7B109463C21F".hexBytes
        let response = try HMSecureContainerCommandResponse(bytes: bytes)

        XCTAssertEqual(response.response, [])
        XCTAssertEqual(response.hmac, "7D3BFC6BE25A497C313209EB92E36E64C92F15267D712D33CBAA7B109463C21F".hexBytes)

        // Check the HMAC
        XCTAssertTrue(try response.isSignatureValid(forKey: "393CAB697CB6CE241AB485E93AE62027DE87BCF9B5DC65B55F32C02DC119CE8C".hexBytes), "Invalid HMAC")
    }

    func testRequest() throws {
        let bytes = "3601003A0020010100030001010100030101010100030201010100030300010200020001020002010102000202010200020301A2000812060E0D080B00B4154BA1380A9D7004CFB514890450887D94C7CAE46F4943BD3FBA48D68B263AAC".hexBytes
        let request = try HMSecureContainerCommandRequest(bytes: bytes)

        XCTAssertEqual(request.command, "0020010100030001010100030101010100030201010100030300010200020001020002010102000202010200020301A2000812060E0D080B00B4".hexBytes)
        XCTAssertEqual(request.header, "36".hexBytes)
        XCTAssertEqual(request.signature, "154BA1380A9D7004CFB514890450887D94C7CAE46F4943BD3FBA48D68B263AAC".hexBytes)
        XCTAssertEqual(request.requiresHMAC, true)

        // Check the HMAC
        XCTAssertTrue(try request.isSignatureValid(forKey:"393CAB697CB6CE241AB485E93AE62027DE87BCF9B5DC65B55F32C02DC119CE8C".hexBytes), "Invalid HMAC")
    }
}
