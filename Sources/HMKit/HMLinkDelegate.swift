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
//  HMLinkDelegate.swift
//  HMKit
//
//  Created by Mikk Rätsep on 11/12/2018.
//

import Foundation


import Foundation


/// `HMLinkDelegated` is used to dispatch `HMLink` events.
/// All callbacks are executed on the **main** thread.
public protocol HMLinkDelegate {

    typealias Approve = () throws -> Void


    /// Callback for when the `HMLink` received an authorisation request.
    ///
    /// - parameters:
    ///     - link: `HMLink` that sent the *authorisation* request.
    ///     - serialNumber: Serial number of the `HMLink` trying to authorise.
    ///     - approve: Block to be called after the user has approved the authorisation (ignore if the user disallowed or ignored the request). Throws a `.timeout` when the block is called after the timeout period.
    ///     - timeout: Amount of seconds it takes for the authorisation to time out.
    /// - warning: If the *approve*-block is *not* called before the timeout interval elapses (starting after this method is invoked), the authorisation fails.
    func link(_ link: HMLink, authorisationRequestedBy serialNumber: [UInt8], approve: @escaping Approve, timeout: TimeInterval)

    /// Callback for when a command has been received from the `HMLink`.
    ///
    /// - parameters:
    ///     - link: `HMLink` that sent the command.
    ///     - bytes: Bytes-array representing the received command.
    ///     - contentType: Type of the data received.
    ///     - requestID: Bytes denoting the *requestID* (could be empty, if wansn't set in sending).
    func link(_ link: HMLink, commandReceived bytes: [UInt8], contentType: HMContainerContentType, requestID: [UInt8])

    /// Callback for when `revoke` was completed on the other device and data was received back.
    ///
    /// - Parameters:
    ///   - link: `HMLink` that was revoked.
    ///   - bytes: Bytes-array of the data sent back.
    func link(_ link: HMLink, revokeCompleted bytes: [UInt8])

    /// Callback for when the `HMLink`'s state has changed.
    ///
    /// - parameters:
    ///     - link: The `HMLink` in question.
    ///     - newState: The new state of the `HMLink`.
    ///     - previousState: Previous state of the `HMLink`.
    func link(_ link: HMLink, stateChanged newState: HMLinkState, previousState: HMLinkState)

    /// Callback for when the `HMLink`'s encountered an error.
    ///
    /// - parameters:
    ///     - link: The `HMLink` in question.
    ///     - error: The error received by the `HMLink`.
    func link(_ link: HMLink, receivedError error: HMProtocolError)
}
