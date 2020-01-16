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
//  HMTelematicsRequestError.swift
//  HMKit
//
//  Created by Mikk Rätsep on 10/05/2019.
//

import Foundation


public struct HMTelematicsRequestError: Decodable, Error, HMTelematicsResponse {

    public let detail: String?
    public let source: String?
    public let title: String
}

struct HMTelematicsResponseErrorsRoot: Decodable {

    private(set) var errors: [HMTelematicsRequestError] = []


    // MARK: CodingKey

    enum Keys: String, CodingKey {
        case errors
    }


    // MARK: Decodable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        var errorsContainer = try container.nestedUnkeyedContainer(forKey: .errors)

        while let error = try errorsContainer.decodeIfPresent(HMTelematicsRequestError.self) {
            errors.append(error)
        }
    }
}
