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
//  AccessCertificateTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 31/05/2018.
//

import HMCryptoKit
import HMKit
import HMUtilities
import XCTest


class AccessCertificateTests: XCTestCase {

    static var allTests = [("testVersionBasic", testVersionBasic),
                           ("testVersionOne", testVersionOne)]


    // MARK: XCTestCase

    func testVersionBasic() {
        /*
         Access certificate v0

         Access Gaining Serial number ( 9 bytes ) - Kes annab cerdi
         Access Gaining Public Key ( 64 bytes ) - Cerdi andja public
         Access Providing Serial number ( 9 bytes )
         Start date ( 5 bytes)
         Byte[0] - Year ( 0 - 255 ) 2000 - 2255
         Byte[1] - Month
         Byte[2] - Day
         Byte[3] - Hour
         Byte[4] - Minute
         End date ( 5 bytes)
         Byte[0] - Year ( 0 - 255 ) 2000 - 2255
         Byte[1] - Month
         Byte[2] - Day
         Byte[3] - Hour
         Byte[4] - Minute
         Permissions Size ( 1 byte )
         Permissions ( 0 - 16 bytes )
         Certificate Authority Signature ( 64 bytes Only for Certificate data )
         */
        let bytes: [UInt8] = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0xDB, 0x8A, 0xD6, 0x8F, 0xAC, 0x18, 0x20,
                              0xCD, 0x8B, 0xC3, 0xF2, 0x69, 0x8B, 0xE8, 0x55, 0x2B, 0xDF, 0xD9, 0xE1, 0x4D, 0xD1, 0x38, 0x3A,
                              0x43, 0x21, 0xDD, 0x28, 0x6C, 0x67, 0x63, 0x75, 0x38, 0x0F, 0x53, 0x68, 0x2F, 0x49, 0xE8, 0xED,
                              0xA2, 0xCC, 0x89, 0x2B, 0x79, 0x57, 0x87, 0x65, 0x37, 0xCA, 0xF7, 0x51, 0x05, 0x41, 0x3A, 0xC0,
                              0x28, 0x56, 0xA5, 0xCB, 0x5B, 0x19, 0x86, 0xD4, 0xC0, 0x88, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22,
                              0x11, 0x00, 0x11, 0x05, 0x1F, 0x00, 0x00, 0x63, 0x0C, 0x1F, 0x00, 0x00, 0x05, 0x10, 0x07, 0xFF,
                              0xF0, 0x07, 0xB9, 0x31, 0x18, 0x94, 0xD7, 0x2E, 0x91, 0x2A, 0xD6, 0xD5, 0x1F, 0x60, 0x2A, 0x29,
                              0x5B, 0xBC, 0x61, 0x1E, 0x58, 0x23, 0x71, 0xD0, 0x86, 0x82, 0xC6, 0xF3, 0x5D, 0xCE, 0x6F, 0xE9,
                              0x6F, 0xB5, 0x6F, 0x31, 0x3C, 0x35, 0xB6, 0xC0, 0x21, 0x41, 0x1B, 0x7C, 0xB2, 0x28, 0x28, 0xE2,
                              0xEE, 0x34, 0xB2, 0xCF, 0xD4, 0x7A, 0x48, 0x31, 0x60, 0x91, 0x09, 0x9C, 0x9B, 0x77, 0xC7, 0xFB,
                              0xFB, 0xFB]
        let accessCertificate = HMAccessCertificate(binary: bytes)

        XCTAssertEqual(accessCertificate?.gainingPublicKey, "DB8AD68FAC1820CD8BC3F2698BE8552BDFD9E14DD1383A4321DD286C676375380F53682F49E8EDA2CC892B7957876537CAF75105413AC02856A5CB5B1986D4C0".hexBytes)
        XCTAssertEqual(accessCertificate?.gainingSerial, "001122334455667788".hexBytes)
        XCTAssertEqual(accessCertificate?.permissions, "1007FFF007".hexBytes)
        XCTAssertEqual(accessCertificate?.providingSerial, "887766554433221100".hexBytes)
        XCTAssertEqual(accessCertificate?.signature, "B9311894D72E912AD6D51F602A295BBC611E582371D08682C6F35DCE6FE96FB56F313C35B6C021411B7CB22828E2EE34B2CFD47A48316091099C9B77C7FBFBFB".hexBytes)
        XCTAssertEqual(accessCertificate?.validity.start, Date(timeIntervalSince1970: 1496178000.0))
        XCTAssertEqual(accessCertificate?.validity.end, Date(timeIntervalSince1970: 4102351200.0))
        XCTAssertEqual(accessCertificate?.version, .basic)

        do {
            let publicKey = try HMCryptoKit.publicKey(binary: "CD5DB8DEB2306E842FFA260D5268679CF38B01B188CA062F621164E45507FDE7B981BF0EC61522E94B3C90E1B52123D0B5036414665D79A03CF2A368BC40C5BB".hexBytes)

            XCTAssertEqual(accessCertificate?.isSignatureValid(forPublicKey: publicKey), true, "Invalid signature")
        }
        catch {
            XCTFail("Issuer public key generation: \(error)")
        }
    }

    func testVersionOne() {
        /*
         Access certificate v1

         Version ( 1 byte ) 0x01 - is used to identify certificate version
         Issuer ( 4 bytes ) - is used in telematics command API
         Access Providing Serial number ( 9 bytes ) - Is used to validate if this certificate is for current device
         Access Gaining Serial number ( 9 bytes )
         Access Gaining Public Key ( 64 bytes )
         Access Providing Serial number ( 9 bytes )
         Start date ( 5 bytes) - is used to validate if certificate can be used
         Byte[0] - Year ( 0 - 255 ) 2000 - 2255
         Byte[1] - Month
         Byte[2] - Day
         Byte[3] - Hour
         Byte[4] - Minute
         End date ( 5 bytes) - is used to validate if certificate is expired
         Byte[0] - Year ( 0 - 255 ) 2000 - 2255
         Byte[1] - Month
         Byte[2] - Day
         Byte[3] - Hour
         Byte[4] - Minute
         Permissions Size ( 1 byte ) - Size of permission bytes
         Permissions ( 0 - 16 bytes ) - is used to validate what this certificate allows to do
         Certificate Authority Signature ( 64 bytes Only for Certificate data ) - is used to validate if this certificate is from trusted system
         */
        let bytes: [UInt8] = [0x01, 0x74, 0x65, 0x73, 0x74, 0x88, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x00, 0x00, 0x11,
                              0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0xDB, 0x8A, 0xD6, 0x8F, 0xAC, 0x18, 0x20, 0xCD, 0x8B,
                              0xC3, 0xF2, 0x69, 0x8B, 0xE8, 0x55, 0x2B, 0xDF, 0xD9, 0xE1, 0x4D, 0xD1, 0x38, 0x3A, 0x43, 0x21,
                              0xDD, 0x28, 0x6C, 0x67, 0x63, 0x75, 0x38, 0x0F, 0x53, 0x68, 0x2F, 0x49, 0xE8, 0xED, 0xA2, 0xCC,
                              0x89, 0x2B, 0x79, 0x57, 0x87, 0x65, 0x37, 0xCA, 0xF7, 0x51, 0x05, 0x41, 0x3A, 0xC0, 0x28, 0x56,
                              0xA5, 0xCB, 0x5B, 0x19, 0x86, 0xD4, 0xC0, 0x11, 0x05, 0x1F, 0x00, 0x00, 0x63, 0x0C, 0x1F, 0x00,
                              0x00, 0x05, 0x10, 0x07, 0xFF, 0xF0, 0x07, 0xA1, 0x8F, 0x26, 0x0C, 0x14, 0x20, 0xD5, 0x21, 0x16,
                              0xF7, 0x44, 0x50, 0x4C, 0x03, 0x76, 0x8F, 0x1F, 0x9F, 0x05, 0xB9, 0x0A, 0xEF, 0x51, 0x4C, 0x51,
                              0xD2, 0xBF, 0xA5, 0x79, 0x11, 0x51, 0x1B, 0x62, 0x2A, 0xA1, 0x94, 0x11, 0x78, 0xE1, 0xA8, 0x8B,
                              0x63, 0xAE, 0x06, 0x3B, 0xC1, 0x96, 0x1A, 0x62, 0x92, 0xBC, 0x78, 0xCE, 0xF9, 0xC3, 0x25, 0xEE,
                              0xE7, 0x90, 0x24, 0x8E, 0xA7, 0x9F, 0x13]
        let accessCertificate = HMAccessCertificate(binary: bytes)

        XCTAssertEqual(accessCertificate?.gainingPublicKey, "DB8AD68FAC1820CD8BC3F2698BE8552BDFD9E14DD1383A4321DD286C676375380F53682F49E8EDA2CC892B7957876537CAF75105413AC02856A5CB5B1986D4C0".hexBytes)
        XCTAssertEqual(accessCertificate?.gainingSerial, "001122334455667788".hexBytes)
        XCTAssertEqual(accessCertificate?.permissions, "1007FFF007".hexBytes)
        XCTAssertEqual(accessCertificate?.providingSerial, "887766554433221100".hexBytes)
        XCTAssertEqual(accessCertificate?.signature, "A18F260C1420D52116F744504C03768F1F9F05B90AEF514C51D2BFA57911511B622AA1941178E1A88B63AE063BC1961A6292BC78CEF9C325EEE790248EA79F13".hexBytes)
        XCTAssertEqual(accessCertificate?.validity.start, Date(timeIntervalSince1970: 1496178000.0))
        XCTAssertEqual(accessCertificate?.validity.end, Date(timeIntervalSince1970: 4102351200.0))
        XCTAssertEqual(accessCertificate?.version, .one(issuer: [0x74, 0x65, 0x73, 0x74]))

        do {
            let publicKey = try HMCryptoKit.publicKey(binary: "B6F72E96139C04186F478F197FB0D7E19038C8A637D4B435F84FBC76FBCC90F1AD5BE5BF736BAD3674E2185D71D48B3CCC7DF1FAEEBF5E0E05A1DB53BB8C6E8C".hexBytes)

            XCTAssertEqual(accessCertificate?.isSignatureValid(forPublicKey: publicKey), true, "Invalid signature")
        }
        catch {
            XCTFail("Issuer public key generation: \(error)")
        }
    }
}
