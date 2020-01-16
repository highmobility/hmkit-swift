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
//  HMOAuthFailure.swift
//  HMKit
//
//  Created by Mikk Rätsep on 13/05/2019.
//

import Foundation


public struct HMOAuthFailure: Error {

    public enum Reason {

        /// Access is denied, or there was an error returned.
        case accessDenied

        /// Some other, internal error happened.
        case internalError

        /// Invalid URL/URI supplied, or combining the URL failed.
        case invalidURL

        /// `HMLocalDevice` has to be initialised beforehand.
        case localDeviceUninitialised

        /// Could not extract the *access token* from the response.
        case missingToken
    }

    public let reason: Reason
    public let state: String?


    init(reason: Reason, state: String? = nil) {
        self.reason = reason
        self.state = state
    }
}
