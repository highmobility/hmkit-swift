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
//  HMPeriod.swift
//  HMKit
//
//  Created by Mikk Rätsep on 25/10/2017.
//

import Foundation


/// Period has both a *start* and an *end* date.
///
/// High-Mobility's `Date` data structure is the following:
/// ```
/// [0]: Year     ( 0 to 99, means year from 2000 to 2099 )
/// [1]: Month    ( 1 to 12 )
/// [2]: Day      ( 1 to 31 )
/// [3]: Hours    ( 0 to 23 )
/// [4]: Minutes  ( 0 to 59 )
/// ```
public struct HMPeriod: Codable {

    public let start: Date
    public let end: Date


    // MARK: Init

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    init?<C: Collection>(from binary: C) where C.Element == UInt8 {
        guard binary.count == 10 else {
            return nil
        }

        guard let start = Date(hmCustomBinary: binary.bytes[0..<5]) else {
            return nil
        }

        guard let end = Date(hmCustomBinary: binary.bytes[5..<10]) else {
            return nil
        }

        self.init(start: start, end: end)
    }
}

extension HMPeriod: Equatable {

    public static func ==(lhs: HMPeriod, rhs: HMPeriod) -> Bool {
        return (lhs.start == rhs.start) && (lhs.end == rhs.end)
    }
}

public extension HMPeriod {

    func isValid(on date: Date) -> Bool {
        guard date >= start else {
            return false
        }

        guard date <= end else {
            return false
        }

        return true
    }
}

extension HMPeriod {

    var hmCustomBinary: [UInt8]? {
        guard let startBytes = start.hmCustomBytes, startBytes.count == 5 else {
            return nil
        }

        guard let endBytes = end.hmCustomBytes, endBytes.count == 5 else {
            return nil
        }

        return startBytes + endBytes
    }
}
