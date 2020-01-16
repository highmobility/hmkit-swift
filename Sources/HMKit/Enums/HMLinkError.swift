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
//  HMLinkError.swift
//  HMKit
//
//  Created by Mikk Rätsep on 08/11/2017.
//

import Foundation


/// The values representing an error encountered by the `HMLink`.
public enum HMLinkError: Error {

    /// Bluetooth is turned off
    case bluetoothOff

    /// Bluetooth is not authorised for this framework (app)
    case bluetoothUnauthorised

    /// A command has not yet received a response
    case commandInProgress

    /// When the command being sent is too big
    case commandTooBig

    /// Link encountered an internal error (commonly releated to invalid data received)
    case internalError

    /// The signature for the command was invalid
    case invalidSignature

    /// The Certificates storage database is full
    case storageFull

    /// Command timed out
    case timeOut

    /// The Link is not connected
    case notConnected

    /// The app is not authorised with the connected link to perform the action
    case unauthorised

    /// Bluetooth Low Energy is unavailable for this device
    case unsupported
}
