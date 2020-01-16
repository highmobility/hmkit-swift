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
//  AuthenticateDoneCommandTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 14/06/2018.
//

@testable import HMKit

import HMCryptoKit
import HMUtilities
import XCTest

/*
 0x40 Authenticate done - This request will tell to HMLink that sensing has finished authentication

 Req:
 Data[2 to 11]: Nonce ( 9 bytes )
 Data[11 to A]: Signature ( command id + Serial number )

 Ack:
 Empty

 Error:
 0x01 - Internal error : When generating nonce fails or adding signature fails
 0x04 - Invalid data : When data size is wrong or this serial number is not paired
 0x06 - Invalid signature : when signature is wrong
 */


class AuthenticateDoneCommandTests: XCTestCase {

    static var allTests = [("testResponse", testResponse),
                           ("testRequest", testRequest)]


    // MARK: XCTestCase

    func testResponse() throws {
        let bytes: [UInt8] = [0x01, 0x40]

        XCTAssertEqual(try HMAuthenticateDoneCommandResponse().bytes, bytes)
    }

    func testRequest() throws {
        let bytes = "408913268B1F5895E51E77844E2788CE94B4B1353023BA2DD7B3B15E054B055D3B237814776E20E7D3923C0DF1A7A406CA7FC07E0493F340AB91F6BBFDBB02CE29639CF13F98B8FA54F6".hexBytes
        let request = try HMAuthenticateDoneCommandRequest(bytes: bytes)

        XCTAssertEqual(request.nonce, "8913268B1F5895E51E".hexBytes)
        XCTAssertEqual(request.signature, "77844E2788CE94B4B1353023BA2DD7B3B15E054B055D3B237814776E20E7D3923C0DF1A7A406CA7FC07E0493F340AB91F6BBFDBB02CE29639CF13F98B8FA54F6".hexBytes)

        // Check the signature
        let publicKeyBytes = "4A116CF85EF1B268D5E68777658BC77E9E5F3AA2BB2EDDBA2CDBD79AEBD63FECAFB15F9648DE82E5C60963EFC8FC9700E8B4B5E653505C1F22FA19169A7F1180".hexBytes
        let publicKey = try HMCryptoKit.publicKey(binary: publicKeyBytes)

        XCTAssertTrue(try request.isSignatureValid(forKey: publicKey), "Invalid signature")
    }
}
