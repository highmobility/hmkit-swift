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
//  HMLocalDeviceDelegate.swift
//  HMKit
//
//  Created by Mikk Rätsep on 11/12/2018.
//

import Foundation


/// `HMLocalDeviceDelegate` is used to dispatch certain `HMLocalDevice` events.
/// All callbacks are executed on the **main** thread.
public protocol HMLocalDeviceDelegate {

    /// Callback for when the `HMLocalDevice`'s state changed.
    ///
    /// - parameters:
    ///     - newState: *New* state of the `HMLocalDevice`.
    ///     - oldState: *Old* state of the `HMLocalDevice`.
    func localDevice(stateChanged newState: HMLocalDeviceState, oldState: HMLocalDeviceState)

    /// Callback for when a new `HMLink` has been received.
    ///
    /// - parameter link: New link.
    func localDevice(didReceiveLink link: HMLink)

    /// Callback for when a `HMLink` has been lost.
    ///
    /// - parameter link: Now-lost link.
    func localDevice(didLoseLink link: HMLink)
}
