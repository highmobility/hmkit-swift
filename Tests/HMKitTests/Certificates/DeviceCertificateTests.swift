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
//  DeviceCertificateTests.swift
//  HMKitTests
//
//  Created by Mikk Rätsep on 31/05/2018.
//

import HMCryptoKit
import HMKit
import HMUtilities
import XCTest


class DeviceCertificateTests: XCTestCase {

    static var allTests = [("testVersionBasic", testVersionBasic)]


    // MARK: XCTestCase

    func testVersionBasic() {
        /*
         Device certificate

         Issuer ( 4 bytes )
         App id ( 12 bytes )
         Serial number ( 9 bytes )
         Public Key ( 64 bytes )
         Certificate Authority Signature ( 64 bytes Only for Certificate data )
         */
        let deviceCertificate = HMDeviceCertificate(base64Encoded: "dGVzdDUSLl/IvBsqbLx/RoAiLS2m4LIbZaSBumQjUaC6KbdPHPap+nvxgWWRQ7Iic0QEdmnYPz4/iCGInIFpVxfILs+nPM7TzTFdDb7TRfNnWBjoGsrAdixSznlKFT9gTrXqWo1UqLTJoJX8fCMVuzF5zOV56ilzBU2HCuH/A99QXYakK5IgVCxm4S4l2nEAyrvQuC09Bnmq")

        XCTAssertEqual(deviceCertificate?.appIdentifier, "35122E5FC8BC1B2A6CBC7F46".hexBytes)
        XCTAssertEqual(deviceCertificate?.issuer, "74657374".hexBytes)
        XCTAssertEqual(deviceCertificate?.publicKey, "A481BA642351A0BA29B74F1CF6A9FA7BF181659143B2227344047669D83F3E3F8821889C81695717C82ECFA73CCED3CD315D0DBED345F3675818E81ACAC0762C".hexBytes)
        XCTAssertEqual(deviceCertificate?.serial, "80222D2DA6E0B21B65".hexBytes)
        XCTAssertEqual(deviceCertificate?.signature, "52CE794A153F604EB5EA5A8D54A8B4C9A095FC7C2315BB3179CCE579EA2973054D870AE1FF03DF505D86A42B9220542C66E12E25DA7100CABBD0B82D3D0679AA".hexBytes)
        XCTAssertEqual(deviceCertificate?.version, .basic)

        guard let publicKeyData = Data(base64Encoded: "HuAHdOCCSP3ajv2BI1pTC78YiTe4PEtqUc5/Bk6iRUrgB4cgqgGKXos1ONGZhbRZ0huO2V1pcgk4MwAFB4vffw==") else {
            return XCTFail("Failed to create issuer's public key data.")
        }

        do {
            let publicKey = try HMCryptoKit.publicKey(binary: publicKeyData)

            XCTAssertEqual(deviceCertificate?.isSignatureValid(forPublicKey: publicKey), true, "Invalid signature")
        }
        catch {
            XCTFail("Issuer public key generation: \(error)")
        }
    }
}
