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
//  HMLoggingOptions.swift
//  HMKit
//
//  Created by Mikk Rätsep on 22/03/2017.
//

import Foundation
import os


// TODO: This can and should be refactored to something better
public struct HMLoggingOptions: OptionSet {

    public static var activeOptions: HMLoggingOptions = []

    public let rawValue: UInt16
    public var useDeviceConsole: Bool = false

    fileprivate var stringValues: [String] {
        var strings: [String] = []

        // This is unpleasant
        if contains(.error) {
            strings.append("error❗️")
        }

        if contains(.general) {
            strings.append("general")
        }

        if contains(.command) {
            strings.append("command")
        }

        if contains(.bluetooth) {
            strings.append("bluetooth")
        }

        if contains(.telematics) {
            strings.append("telematics 🌍")
        }

        if contains(.encryption) {
            strings.append("encryption")
        }

        if contains(.maidu) {
            strings.append("maidu")
        }

        if contains(.urlRequests) {
            strings.append("urlRequests")
        }

        if contains(.oauth) {
            strings.append("oauth")
        }

        return strings
    }

    fileprivate var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.dateFormat = "HH:mm:ss.SSS"

        return formatter
    }()


    // MARK: Options

    /// Logs encountered errors.
    public static let error         = HMLoggingOptions(rawValue: 1 << 0)

    /// Logs general events.
    public static let general       = HMLoggingOptions(rawValue: 1 << 1)

    /// Logs executing commands.
    public static let command       = HMLoggingOptions(rawValue: 1 << 2)

    /// Logs bluetooth communication.
    public static let bluetooth     = HMLoggingOptions(rawValue: 1 << 3)

    /// Logs telematics communication.
    public static let telematics    = HMLoggingOptions(rawValue: 1 << 4)

    /// Logs encrypted communication.
    public static let encryption    = HMLoggingOptions(rawValue: 1 << 5)

    /// Logs extra deep bluetooth info.
    public static let maidu         = HMLoggingOptions(rawValue: 1 << 6)

    /// Logs telematics requests.
    public static let urlRequests   = HMLoggingOptions(rawValue: 1 << 7)

    /// Logs the OAuth errors.
    public static let oauth         = HMLoggingOptions(rawValue: 1 << 8)


    // MARK: Init

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}


func log(_ items: Any..., types: HMLoggingOptions) {
    guard HMLoggingOptions.activeOptions.contains(types) else {
        return
    }

    let typesStr = types.stringValues.joined(separator: ", ")
    let text: String

    // Extract the "values"
    if let items = items as? [String] {
        text = "\n\t" + items.joined(separator: "\n\t")
    }
    else {
        text = "\n\t" + items.map { "\($0)" }.joined(separator: "\n\t")
    }

    // Use the desired logging
    if HMLoggingOptions.activeOptions.useDeviceConsole {
        let customLog = OSLog(subsystem: "com.high-mobility.hmkit", category: typesStr)

        os_log("%{public}@", log: customLog, type: .debug, text)
    }
    else {
        let dateStr = HMLoggingOptions.activeOptions.dateFormatter.string(from: Date())

        print("HMKit – " + dateStr + " – " + typesStr + text)
    }
}
