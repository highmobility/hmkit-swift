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
//  Date+Extensions.swift
//  HMKit
//
//  Created by Mikk Rätsep on 23/10/2017.
//

import Foundation


extension Date {

    var hmCustomBytes: [UInt8]? {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self)

        guard let year = components.year, let month = components.month, let day = components.day, let hour = components.hour, let minute = components.minute else {
            return nil
        }

        return [year.uint8, month.uint8, day.uint8, hour.uint8, minute.uint8]
    }


    init?<C: Collection>(hmCustomBinary binary: C) where C.Element == UInt8 {
        guard binary.count == 5 else {
            return nil
        }

        var components = DateComponents()

        components.year = 2000 + binary.bytes[0].int
        components.month = binary.bytes[1].int
        components.day = binary.bytes[2].int
        components.hour = binary.bytes[3].int
        components.minute = binary.bytes[4].int

        guard let date = Calendar.current.date(from: components) else {
            return nil
        }

        self = date
    }
}
