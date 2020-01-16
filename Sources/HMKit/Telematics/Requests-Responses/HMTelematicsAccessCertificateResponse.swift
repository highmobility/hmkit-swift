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
//  HMTelematicsAccessCertificateResponse.swift
//  HMKit
//
//  Created by Mikk Rätsep on 10/05/2019.
//

import Foundation


struct HMTelematicsAccessCertificateResponse: Decodable {

    let device: HMAccessCertificate
    let vehicle: HMAccessCertificate?


    // MARK: CodingKey

    enum Keys: String, CodingKey {
        case device = "device_access_certificate"
        case vehicle = "vehicle_access_certificate"
    }


    // MARK: Decodable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let deviceB64 = try container.decode(String.self, forKey: .device)
        let vehicleB64 = try container.decode(String?.self, forKey: .vehicle)

        guard let deviceAC = HMAccessCertificate(base64Encoded: deviceB64) else {
            throw HMTelematicsError.invalidData
        }

        device = deviceAC
        vehicle = HMAccessCertificate(base64Encoded: vehicleB64 ?? "")
    }
}

extension HMTelematicsAccessCertificateResponse: HMTelematicsResponse {

}
