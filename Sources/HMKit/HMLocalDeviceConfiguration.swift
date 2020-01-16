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
//  HMLocalDeviceConfiguration.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/11/2018.
//

import Foundation


public struct HMLocalDeviceConfiguration {

    public enum ContainerVersion {
        case one
        case two
    }


    /// Set the bluetooth advertisment filter.
    ///
    /// Value, if set, must be **9-bytes**, otherwise change is ignored.
    /// If not set (`nil` used) the filter is cleared.
    ///
    /// Sets the advertisment data to contain the *filter* (i.e. a vehicle's serial),
    /// for the scanning device (i.e. the vehicle) to find this device more easily among many.
    ///
    /// Must restart broadcasting for changes to take effect.
    /// Defaults to `nil`.
    ///
    /// - SeeAlso: `isBroadcastingFilterActive`
    public var broadcastingFilter: Data? {
        get {
            return broadcastingFilterAllowedValue
        }
        set {
            if let value = newValue, value.count != 9 {
                return
            }

            broadcastingFilterAllowedValue = newValue
        }
    }

    /// Set the version of Secure Container (and Telematics Container)
    ///
    /// Must restart communications for the the change to take effect.
    /// Only changes the outgoing (initial) version,
    /// if the receiver uses a different one, the incoming version will be detected automatically.
    ///
    /// Defaults to `.two`.
    ///
    /// - warning: Shouldn't be changed if the receiver's version isn't known.
    public var containerVersion: ContainerVersion = .two

    /// Enable for *safety-critical* connections, that need to track the *connection state*.
    ///
    /// Bluetooth's own connection state changes are designed to be power-efficient, but lazy.
    /// Defaults to `false`.
    public var isAlivePingActive: Bool = false {
        didSet {
            HMLocalDevice.shared.bluetooth.checkAlivePingState()
        }
    }

    /// If the *broadcasting* filter is active in this configuration.
    ///
    /// - SeeAlso: `broadcastingFilter`
    public var isBroadcastingFilterActive: Bool {
        return broadcastingFilter != nil
    }

    /// Enable encryption of commands.
    ///
    /// Defaults to `true`.
    public var isEncryptionEnabled = true

    /// When `true`, will disable the *HM 12345*-type of device name.
    ///
    /// Must restart broadcasting for changes to take effect.
    /// Defaults to `nil`.
    public var overrideAdvertisementName: Bool = false


    // MARK: Private "Storage" Vars

    private var broadcastingFilterAllowedValue: Data?


    // MARK: Init

    /// Initialise the configuration.
    ///
    /// - Parameters:
    ///   - broadcastingFilter: Set the bluetooth advertisment filter, must be **9-bytes**.
    ///   - overrideAdvertisementName: When `true`, will disable the *HM 12345*-type of device name.
    public init<C: Collection>(broadcastingFilter: C? = nil,
                               overrideAdvertisementName: Bool? = nil) where C.Element == UInt8 {
        self.broadcastingFilter = broadcastingFilter?.data

        if let overrideAdvertisementName = overrideAdvertisementName {
            self.overrideAdvertisementName = overrideAdvertisementName
        }
    }
}
