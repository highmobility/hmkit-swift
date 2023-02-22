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
//  HMTelematicsAPI.swift
//  HMKit
//
//  Created by Mikk Rätsep on 12/05/2019.
//

import Foundation


enum HMTelematicsAPI {

    enum Base: String {
        case xvhm
        case sbox

        @available(*, unavailable, renamed: "sbox")
        case test

        var url: String {
            switch self {
            case .xvhm:         return "https://api.high-mobility.com"
            case .test, .sbox:  return "https://sandbox.api.high-mobility.com"
            } 
        }
    }


    enum Endpoint: String {

        case accessCertificates = "access_certificates"
        case commands = "telematics_commands"
        case nonce = "nonces"


        var url: URL? {
            URL(string: HMTelematics.urlBasePath)?
                .appendingPathComponent("v1")
                .appendingPathComponent(rawValue)
        }
    }
}
