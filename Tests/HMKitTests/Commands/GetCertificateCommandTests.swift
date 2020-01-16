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
//  GetCertificateCommandTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 15/06/2018.
//

@testable import HMKit

import HMCryptoKit
import HMUtilities
import XCTest

/*
 0x34 Get certificate - This command is used to ask public key from wearable when it is not existing. Command contains local master signature and response contains server master signature.
 Then can wearable check that request came from trusted place and public key receiver can check that public key came from server.

 Req:
 Data[2 to 11]: Serial number ( 9 bytes )
 Data[11 to A]: signature ( command id + serial number ) local master signature

 Ack:
 Cert Data[3 to 12]: Access Gaining Serial number ( 9 bytes )
 Cert Data[12 to 76]: Access Gaining Public Key ( 64 bytes )
 Cert Data[76 to 85]: Access Providing Serial number ( 9 bytes )
 Cert Data[85 to 90]: Start date ( 5 bytes)
 Cert Data[90 to 95]: End date ( 5 bytes)
 Cert Data[95]: Permissions Size ( 1 byte )
 Cert Data[96 to A]: Permissions ( 0 - 16 bytes )
 Signature Data[A to B]: Certificate Authority Signature ( 64 bytes Only for Certificate data )

 Error:
 0x01 - Internal error : when reading cert from storage fails
 0x04 - Invalid data : when data size is wrong or there is no certificate for that serial number
 0x06 - Invalid signature : when signature is wrong
 */

class GetCertificateCommandTests: XCTestCase {

    static var allTests = [("testResponse", testResponse),
                           ("testRequest", testRequest)]


    // MARK: XCTestCase

    func testResponse() throws {
        let bytes = "0133 0174657374887766554433221100001122334455667788DB8AD68FAC1820CD8BC3F2698BE8552BDFD9E14DD1383A4321DD286C676375380F53682F49E8EDA2CC892B7957876537CAF75105413AC02856A5CB5B1986D4C011051F0000630C1F0000051007FFF007A18F260C1420D52116F744504C03768F1F9F05B90AEF514C51D2BFA57911511B622AA1941178E1A88B63AE063BC1961A6292BC78CEF9C325EEE790248EA79F13".hexBytes
        let response = try HMGetAccessCertificateCommandResponse(bytes: bytes)
        let certificate = response.accessCertificate

        XCTAssertEqual(certificate.gainingSerial, "001122334455667788".hexBytes)
        XCTAssertEqual(certificate.gainingPublicKey, "DB8AD68FAC1820CD8BC3F2698BE8552BDFD9E14DD1383A4321DD286C676375380F53682F49E8EDA2CC892B7957876537CAF75105413AC02856A5CB5B1986D4C0".hexBytes)
        XCTAssertEqual(certificate.providingSerial, "887766554433221100".hexBytes)
        XCTAssertEqual(certificate.permissions, "1007FFF007".hexBytes)
        XCTAssertEqual(certificate.signature, "A18F260C1420D52116F744504C03768F1F9F05B90AEF514C51D2BFA57911511B622AA1941178E1A88B63AE063BC1961A6292BC78CEF9C325EEE790248EA79F13".hexBytes)
        // That should be plenty to Verify the command gets an Access Cert
    }

    func testRequest() throws {
        let bytes = "34 001122334455667788 05B9CAD763897DBACB3669534122058EB2C42B80FCEE7DE6CEC0825053A9988B08DC63E5773254C9E7CE1478A11D5BCFDD1AA825BEB04B6B171E646643EBC10E".hexBytes
        let request = try HMGetAccessCertificateCommandRequest(bytes: bytes)

        XCTAssertEqual(request.serial, "001122334455667788".hexBytes)
        XCTAssertEqual(request.signature, "05B9CAD763897DBACB3669534122058EB2C42B80FCEE7DE6CEC0825053A9988B08DC63E5773254C9E7CE1478A11D5BCFDD1AA825BEB04B6B171E646643EBC10E".hexBytes)

        // Check the signature
        let publicKeyBytes = "325CC6846D160DE14F3028F45D48BEA52A7151EF5382D9CDB393457F59ED2586A6C41D20D9C5850AF27E405500AAC9BFC95F5E314D770EAC39EFF5317512FB0E".hexBytes
        let publicKey = try HMCryptoKit.publicKey(binary: publicKeyBytes)


        XCTAssertTrue(try request.isSignatureValid(forKey: publicKey), "Invalid signature")
    }
}















