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
//  RegisterCertificateCommandTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 15/06/2018.
//

@testable import HMKit

import HMUtilities
import XCTest

/*
 0x32 Register certificate - With this request you can send access certificate to device.
 If it is HMLink then it is not allowed when get device certificate is not done and certificate authority signature is not validated.

 Req:
 Cert Data[2 to 11]: Access Gaining Serial number ( 9 bytes )
 Cert Data[11 to 75]: Access Gaining Public Key ( 64 bytes )
 Cert Data[75 to 84]: Access Providing Serial number ( 9 bytes )
 Cert Data[84 to 89]: Start date ( 5 bytes)
 Cert Data[89 to 94]: End date ( 5 bytes)
 Cert Data[94]: Permissions Size ( 1 byte )
 Cert Data[95 to A]: Permissions ( 0 - 16 bytes )
 Signature Data[A to B]: Certificate Authority Signature ( 64 bytes Only for Certificate data )

 Ack:
 Data[3 to 67]: Public key
 Data[67 to A]: Signature ( ack + Public key )

 Error:
 0x01 - Internal error : when getting public key fails or when adding signature fails
 0x04 - Invalid data : when data size is wrong or serial number does not match
 0x05 - Storage full : when there is no space to store public key
 0x06 - Invalid signature : when signature is wrong
 0x09 - timeout: when we did not get user feedback
 0x10 - Not accepted : when providing serial is wrong
 */

class RegisterCertificateCommandTests: XCTestCase {

    static var allTests = [("testResponse", testResponse),
                           ("testRequest", testRequest)]


    // MARK: XCTestCase

    func testResponse() throws {
        let bytes = "0132325CC6846D160DE14F3028F45D48BEA52A7151EF5382D9CDB393457F59ED2586A6C41D20D9C5850AF27E405500AAC9BFC95F5E314D770EAC39EFF5317512FB0E9532C9AE56E194868AF8C329E122061FF85D56A4BF0AE16FE43F31D2ED64693CC92215F1E264B01358C05A95A55BC0A1BC5D365AAEE526567B0B2A61214E8C8F".hexBytes
        let response = try HMRegisterCertificateCommandResponse(bytes: bytes)

        XCTAssertEqual(response.publicKey.bytes, "325CC6846D160DE14F3028F45D48BEA52A7151EF5382D9CDB393457F59ED2586A6C41D20D9C5850AF27E405500AAC9BFC95F5E314D770EAC39EFF5317512FB0E".hexBytes)
    }

    func testRequest() throws {
        let bytes = "320174657374887766554433221100001122334455667788DB8AD68FAC1820CD8BC3F2698BE8552BDFD9E14DD1383A4321DD286C676375380F53682F49E8EDA2CC892B7957876537CAF75105413AC02856A5CB5B1986D4C011051F0000630C1F0000051007FFF007A18F260C1420D52116F744504C03768F1F9F05B90AEF514C51D2BFA57911511B622AA1941178E1A88B63AE063BC1961A6292BC78CEF9C325EEE790248EA79F13".hexBytes
        let request = try HMRegisterCertificateCommandRequest(bytes: bytes)
        let certificate = request.accessCertificate

        XCTAssertEqual(certificate.gainingSerial, "001122334455667788".hexBytes)
        XCTAssertEqual(certificate.gainingPublicKey, "DB8AD68FAC1820CD8BC3F2698BE8552BDFD9E14DD1383A4321DD286C676375380F53682F49E8EDA2CC892B7957876537CAF75105413AC02856A5CB5B1986D4C0".hexBytes)
        XCTAssertEqual(certificate.providingSerial, "887766554433221100".hexBytes)
        XCTAssertEqual(certificate.permissions, "1007FFF007".hexBytes)
        XCTAssertEqual(certificate.signature, "A18F260C1420D52116F744504C03768F1F9F05B90AEF514C51D2BFA57911511B622AA1941178E1A88B63AE063BC1961A6292BC78CEF9C325EEE790248EA79F13".hexBytes)
        // That should be plenty to Verify the command gets an Access Cert
    }
}
