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
//  GetDeviceCertificateCommandTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 14/06/2018.
//

@testable import HMKit

import HMCryptoKit
import HMUtilities
import XCTest

/*
 0x31 Get device certificate

 Req:
 Data[2 to 11]: Nonce ( 9 bytes )
 Data[11 to A]: Certificate Authority Signature ( Nonce ) or Car signature ( Nonce what contains "0 0 0 0 0 0 0 0 0" )

 Ack:
 Data[3 to 156]: Device certificate

 Error:
 0x04 - Invalid data : when data size is wrong
 0x06 - Invalid signature : when signature is wrong
 0x01 - Internal error : when getting serial number fails
 */

class GetDeviceCertificateCommandTests: XCTestCase {

    static var allTests = [("testResponse", testResponse),
                           ("testRequest", testRequest)]


    // MARK: XCTestCase

    func testResponse() throws {
        let bytes = "0131746573743EAAF6A4F2379BC6302F415F3EB40D8E82EAD896A18B994580FB6FDC22B5FF3C80331854DE314483A28E5F1F59369CFD3EF84FE5EB46230D397622080DC6888D9680E47510CFD13D289CE14EEDF355CC62CF8A61983E91C89778F401814EA2A59B58D41067DA9BFC5A16ECD639A38A14D89EE9DB7EA9285450BF844D4B3CF5624711E3C66D58CE4408E2DCE647F75EB5AAB499F5CA".hexBytes
        let response = try HMGetDeviceCertificateCommandResponse(bytes: bytes)
        let certificate = response.deviceCertificate

        XCTAssertEqual(certificate.appIdentifier, "3EAAF6A4F2379BC6302F415F".hexBytes)
        XCTAssertEqual(certificate.issuer, "74657374".hexBytes)
        XCTAssertEqual(certificate.publicKey, "8B994580FB6FDC22B5FF3C80331854DE314483A28E5F1F59369CFD3EF84FE5EB46230D397622080DC6888D9680E47510CFD13D289CE14EEDF355CC62CF8A6198".hexBytes)
        XCTAssertEqual(certificate.serial, "3EB40D8E82EAD896A1".hexBytes)
        XCTAssertEqual(certificate.signature, "3E91C89778F401814EA2A59B58D41067DA9BFC5A16ECD639A38A14D89EE9DB7EA9285450BF844D4B3CF5624711E3C66D58CE4408E2DCE647F75EB5AAB499F5CA".hexBytes)
        XCTAssertEqual(certificate.version, .basic)

        // Check the signature
        let publicKeyBytes = "D0141B2821D0CD5CFCDB6A6075BAE4AF822A03D86F6A6A1C5DCA5EFB53A448BAE697D097C1E8D69DB7FFDB68CD0C91A6A612FC309BC23232B50AEC38748134A3".hexBytes
        let publicKey = try HMCryptoKit.publicKey(binary: publicKeyBytes)

        XCTAssertTrue(certificate.isSignatureValid(forPublicKey: publicKey), "Invalid signature")
    }

    func testRequest() throws {
        let bytes = "31000000000000000000012E478268824D2F84763E6177BBFC52C5ED4468254B3C2CD4DF3DE1551DA077316B80CBBFB5FDD82EB560FCF35EA10AB8DA02F27D8575D7495E52A0B6A7ADEF".hexBytes
        let request = try HMGetDeviceCertificateCommandRequest(bytes: bytes)

        XCTAssertEqual(request.nonce, "000000000000000000".hexBytes)
        XCTAssertEqual(request.signature, "012E478268824D2F84763E6177BBFC52C5ED4468254B3C2CD4DF3DE1551DA077316B80CBBFB5FDD82EB560FCF35EA10AB8DA02F27D8575D7495E52A0B6A7ADEF".hexBytes)

        // Check the signature
        let publicKeyBytes = "4A116CF85EF1B268D5E68777658BC77E9E5F3AA2BB2EDDBA2CDBD79AEBD63FECAFB15F9648DE82E5C60963EFC8FC9700E8B4B5E653505C1F22FA19169A7F1180".hexBytes
        let publicKey = try HMCryptoKit.publicKey(binary: publicKeyBytes)

        guard let accessCert = HMAccessCertificate(base64Encoded: "AXRtY3M+tA2OgurYlqFtYUtv9v0ZOodKEWz4XvGyaNXmh3dli8d+nl86orsu3bos29ea69Y/7K+xX5ZI3oLlxglj78j8lwDotLXmU1BcHyL6GRaafxGAEgYGDiUXBgYOJRAQB//9/+//////AwAAAAAAJtWqesl5VY8jX8b7436KiyXXpSscxBxhxEHwucgPdMUpwoSrIsZRUOjU/UvJrGOo/JSMPopZF3nLCYOiSCX1NQ==") else {
            return XCTFail("Access certificate init")
        }

        // TODO: Needs to check the supplied AC
        XCTAssertTrue(try request.isSignatureValid(forKey: publicKey), "Invalid signature")
    }
}
