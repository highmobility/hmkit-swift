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
//  AuthenticateCommandTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 14/06/2018.
//

@testable import HMKit

import HMCryptoKit
import HMUtilities
import XCTest

/*
 0x35 Authenticate - This request will start connection between two devices.

 Req:
 Data[2 to 11]: Serial number ( 9 bytes )
 Data[11 to A]: Signature ( command id + Serial number )

 Ack:
 Data[3 to 12]: Nonce ( 9 Bytes )
 Data[12 to A]: signature ( ack + Nonce)

 Error:
 0x01 - Internal error : When generating nonce fails or adding signature fails
 0x04 - Invalid data : When data size is wrong or this serial number is not paired
 0x06 - Invalid signature : when signature is wrong
 */


class AuthenticateCommandTests: XCTestCase {

    static var allTests = [("testResponse", testResponse),
                           ("testRequest", testRequest)]


    // MARK: XCTestCase

    func testResponse() throws {
        let bytes = "01354ACCD30848507CB22D0F7798D86980D26F9DCA582D6D1F27807D14991565F3FE152F6E859823928C7F90444AAA6FF15D10510143FF2C889270835C6B749FEE8BA410224CE0D3AB9BD9".hexBytes
        let response = try HMAuthenticateCommandResponse(bytes: bytes)

        XCTAssertEqual(response.nonce, "4ACCD30848507CB22D".hexBytes)
        XCTAssertEqual(response.signature, "0F7798D86980D26F9DCA582D6D1F27807D14991565F3FE152F6E859823928C7F90444AAA6FF15D10510143FF2C889270835C6B749FEE8BA410224CE0D3AB9BD9".hexBytes)

        // Check the signature
        let publicKeyBytes = "8B994580FB6FDC22B5FF3C80331854DE314483A28E5F1F59369CFD3EF84FE5EB46230D397622080DC6888D9680E47510CFD13D289CE14EEDF355CC62CF8A6198".hexBytes
        let publicKey = try HMCryptoKit.publicKey(binary: publicKeyBytes)

        XCTAssertTrue(try response.isSignatureValid(forKey: publicKey), "Invalid signature")
    }

    func testRequest() throws {
        let bytes = "356D614B6FF6FD193A87DF497FC1940E2E656F2FEA52E8AB1D6D086C2820E3B081E30149EC01D87BE1E640A1C616687970DB78DAB328125CBF45B76B45D865A9F66DB2344BC8E081D590".hexBytes
        let request = try HMAuthenticateCommandRequest(bytes: bytes)

        XCTAssertEqual(request.serial, "6D614B6FF6FD193A87".hexBytes)
        XCTAssertEqual(request.signature, "DF497FC1940E2E656F2FEA52E8AB1D6D086C2820E3B081E30149EC01D87BE1E640A1C616687970DB78DAB328125CBF45B76B45D865A9F66DB2344BC8E081D590".hexBytes)

        // Check the signature
        let publicKeyBytes = "4A116CF85EF1B268D5E68777658BC77E9E5F3AA2BB2EDDBA2CDBD79AEBD63FECAFB15F9648DE82E5C60963EFC8FC9700E8B4B5E653505C1F22FA19169A7F1180".hexBytes
        let publicKey = try HMCryptoKit.publicKey(binary: publicKeyBytes)

        XCTAssertTrue(try request.isSignatureValid(forKey: publicKey), "Invalid signature")
    }
}
