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
//  HMLocalDevice.swift
//  HMKit
//
//  Created by Mikk Rätsep on 02/11/2018.
//

import CoreBluetooth
import Foundation
import HMCryptoKit


public typealias HMBase64String = String


public class HMLocalDevice {

    /// Singleton access for the `HMLocalDevice`, read-only.
    public static let shared: HMLocalDevice = HMLocalDevice()


    // MARK: Vars

    /// `HMDeviceCertificate` of the device.
    public internal(set) var certificate: HMDeviceCertificate?

    /// Some configurable settings for `HMLocalDevice`.
    ///
    /// Changing some *configuration* settings while the device is broadcasting
    /// won't have an effect and the broadcasting needs to be restarted.
    ///
    /// - SeeAlso: `HMLocalDeviceConfiguration`
    public var configuration = HMLocalDeviceConfiguration(broadcastingFilter: Optional<Data>.none, overrideAdvertisementName: nil)

    /// Object that conforms to `HMLocalDeviceDelegate` for callbacks from the `HMLocalDevice`.
    ///
    /// - SeeAlso: `HMLocalDeviceDelegate`
    public var delegate: HMLocalDeviceDelegate?

    /// `OptionSet` that configures the type of logs printed to the console; defaults to `.general`.
    ///
    /// - seeAlso: `LoggingOptions`
    public var loggingOptions: HMLoggingOptions = [.general] {
        didSet {
            HMLoggingOptions.activeOptions = loggingOptions
        }
    }

    /// Name of the device.
    public internal(set) var name: String

    /// State of the `HMLocalDevice` singleton, read-only.
    ///
    /// Changes are sent to the `delegate` as well.
    ///
    /// - SeeAlso: `HMLocalDeviceDelegate`
    public internal(set) var state: HMLocalDeviceState = .bluetoothUnavailable


    private(set) var bluetooth: HMBluetooth
    private(set) var privateKey: SecKey!
    private(set) var issuerPublicKey: SecKey!


    // MARK: Init

    private init() {
        bluetooth = HMBluetooth()
        name = String.generateNewAdvertismentName()
    }
}

public extension HMLocalDevice {

    var links: Set<HMLink> {
        bluetooth.links
    }

    /// `HMAccessCertificate`-s registered with the `HMLocalDevice`, read-only.
    var registeredCertificates: [HMAccessCertificate] {
        get {
            guard let certificate = certificate else {
                return []
            }

            return HMStorage.shared.certificates.filter { $0.providingSerial == certificate.serial }
        }
    }

    /// Convenience accessor for the device's *serial*.
    var serial: [UInt8]? {
        return certificate?.serial
    }

    /// `HMAccessCertificate`-s stored with the `HMLocalDevice`, read-only.
    var storedCertificates: [HMAccessCertificate] {
        get {
            guard let certificate = certificate else {
                return []
            }

            return HMStorage.shared.certificates.filter { $0.providingSerial != certificate.serial }
        }
    }


    // MARK: Methods

    /// Stops broadcasting, removes the services (thus disconnecting from centrals) and clears the links.
    func disconnect() {
        bluetooth.disconnect()

        guard state != .bluetoothUnavailable else {
            return
        }

        // And update the state
        changeState(to: .idle)
    }

    /// Initialise the `HMLocalDevice` with essential values before using any other functionality.
    ///
    /// - Parameters:
    ///   - certificate: The `HMDeviceCertificate` for this device.
    ///   - devicePrivateKey: The private key for this device in `HMECKey` format.
    ///   - issuerPublicKey: The issuer's public key in `HMECKey` format.
    ///
    /// - Throws: `invalidInput` when the keys are of invalid length.
    func initialise(certificate: HMDeviceCertificate, devicePrivateKey: SecKey, issuerPublicKey: SecKey) throws {
        // Check the keys' lengths
        guard devicePrivateKey.count == 32, issuerPublicKey.count == 64 else {
            throw HMLocalDeviceError.invalidInput
        }

        // Set the vars
        self.certificate = certificate
        self.privateKey = devicePrivateKey
        self.issuerPublicKey = issuerPublicKey

        HMTelematics.updateBasePath(from: certificate)

        log("HMLocalDevice initialised ✅", types: .general)
    }

    /// Convenience initialiser for `HMLocalDevice` with essential values before using any other functionality.
    ///
    /// Inputs are `Base64` encoded strings.
    ///
    /// - Parameters:
    ///     - certificate: Data for `HMDeviceCertificate` in a *base64* format.
    ///     - devicePrivateKey: Private key (elliptic curve p256v1) for this device; must be **32 bytes** and match the public key in `HMDeviceCertificate`.
    ///     - issuerPublicKey: Public key of the Issuer; must be **64 bytes**.
    ///
    /// - Throws:
    ///   - `invalidInput` when the `HMDeviceCertificate` could not be created from the input.
    ///   - `invalidInput` too, when the keys' base64 string is invalid.
    ///   - `HMCryptoKitError` when keys could not be created.
    func initialise(certificate: HMBase64String, devicePrivateKey: HMBase64String, issuerPublicKey: HMBase64String) throws {
        // Create the certificate
        guard let deviceCertificate = HMDeviceCertificate(base64Encoded: certificate) else {
            throw HMLocalDeviceError.invalidInput
        }

        // Create the private key
        guard let privateKeyData = Data(base64Encoded: devicePrivateKey) else {
            throw HMLocalDeviceError.invalidInput
        }

        let privateKey = try HMCryptoKit.privateKey(privateKeyBinary: privateKeyData.bytes, publicKeyBinary: deviceCertificate.publicKey)

        // Create the issuer's public key
        guard let publicKeyData = Data(base64Encoded: issuerPublicKey) else {
            throw HMLocalDeviceError.invalidInput
        }

        let publicKey = try HMCryptoKit.publicKey(binary: publicKeyData)

        // Call the "real" initialiser
        try initialise(certificate: deviceCertificate, devicePrivateKey: privateKey, issuerPublicKey: publicKey)
    }

    /// Convenience method for checking if the `HMAccessCertificate`-s database has a matching certificate.
    ///
    /// The matching `HMAccessCertificate`'s *gaining* serial number is that of the input.
    /// Also, the *providing* serial number must match `HMLocalDevice`'s serial number.
    ///
    /// Generic input can be for an example `[UInt8]` or `Data`.
    ///
    /// - Parameters:
    ///     - serial: Serial number of the *other* device; must be **9 bytes**.
    ///
    /// - Throws:
    ///     - `invalidInput` when the serial number is wrong size.
    ///     - `uninitialised` when `HMLocalDevice` is uninitialised.
    ///
    /// - Returns: `true` when there is a matching (authorised) `HMAccessCertificate`.
    func isAuthorised<C: Collection>(toVehicle serial: C) throws -> Bool where C.Element == UInt8 {
        guard serial.count == 9 else {
            throw HMLocalDeviceError.invalidInput
        }

        guard let deviceSerial = certificate?.serial else {
            throw HMLocalDeviceError.uninitialised
        }

        return HMStorage.shared.certificates.contains {
            ($0.gainingSerial == serial.bytes) && ($0.providingSerial == deviceSerial)
        }
    }

    /// Registers an `HMAccessCertificate` with the `HMLocalDevice`.
    ///
    /// If a similar certificate is already registered,
    /// the old one will be deleted and the new one added.
    ///
    /// - Parameters:
    ///     - certificate: Certificate that will be used to *authenticate* with connecting devices.
    ///
    /// - Throws:
    ///   - `uninitialised` when `HMLocalDevice` is uninitialised.
    ///   - `internalError` when `HMDeviceCertificate` is not set or the providing serial does not match the `HMDeviceCertificate` one.
    func register(certificate: HMAccessCertificate) throws {
        guard let deviceCertificate = self.certificate else {
            throw HMLocalDeviceError.uninitialised
        }

        guard certificate.providingSerial == deviceCertificate.serial else {
            throw HMLocalDeviceError.internalError
        }

        HMStorage.shared.storeCertificate(certificate)
    }

    /// Reset (clear) the `HMLocalDevice`'s `HMAccessCertificate`-s database.
    func resetStorage() {
        HMStorage.shared.resetStorage()
    }

    /// Revoke `HMAccessCertificate`-s registered or stored with the `HMLocalDevice`.
    ///
    /// Generic input can be for an example `[UInt8]` or `Data`.
    ///
    /// - Parameters:
    ///   - serial: The *serial number* of a device's serial; must be **9 bytes**.
    ///   - type: Either *gaining* or *providing.
    ///
    /// - Returns: The `HMAccessCertificate` which was deleted.
    @discardableResult func revokeCertificate<C: Collection>(withSerial serial: C, type: HMSerialType) -> HMAccessCertificate? where C.Element == UInt8 {
        return HMStorage.shared.deleteCertificate(withSerial: serial, type: type)
    }

    /// Start broadcasting the `HMLocalDevice` via BLE advertising.
    ///
    /// - Parameter configuration: `HMLocalDeviceConfiguration` or `nil` – if latter, the previously set (or the *default*) configuration is used.
    ///
    /// - Throws:
    ///   - `invalidInput` when the *broadcasting filter* is set and is not *9 bytes*.
    ///   - `uninitialised` when `HMLocalDevice` is uninitialised.
    ///   - `bluetooth(.alreadyBroadcasting)` when the device is already broadcasting.
    ///
    /// - SeeAlso:
    ///     - `HMLocalDeviceConfiguration`
    ///     - 'stopBroadcasting()`
    func startBroadcasting(with configuration: HMLocalDeviceConfiguration? = nil) throws {
        guard let certificate = certificate else {
            throw HMLocalDeviceError.uninitialised
        }

        guard !bluetooth.isAdvertising else {
            throw HMLocalDeviceError.bluetooth(.alreadyBroadcasting)
        }

        // Check peripheralManager's state-error
        if let bluetoothError = bluetooth.error {
            changeState(to: .bluetoothUnavailable)

            throw HMLocalDeviceError.bluetooth(bluetoothError)
        }

        // Update the configuration if one was given
        if let configuration = configuration {
            self.configuration = configuration
        }

        // Combine the advertisment options
        let data = try advertismentData(for: certificate, configuration: self.configuration)
        let serviceUUIDs = [CBUUID(data: data)]
        var options: [String : Any] = [CBAdvertisementDataServiceUUIDsKey : serviceUUIDs]

        // Add the name to broadcasting data, if not set to override
        if !self.configuration.overrideAdvertisementName {
            options[CBAdvertisementDataLocalNameKey] = name
        }

        // Finally start broadcasting/advertising
        bluetooth.startAdvertising(options: options)
    }

    /// Stop broadcasting the `HMLocalDevice`.
    func stopBroadcasting() {
        bluetooth.stopAdvertising()

        // And update the state
        changeState(to: .idle)
    }

    /// Stores an `HMAccessCertificate` with the `HMLocalDevice`.
    ///
    /// This certificate is usually read by other devices.
    ///
    /// If a similar certificate is already stored,
    /// the old one will be deleted and the new one added.
    ///
    /// - Parameters:
    ///     - certificate: Certificate that will be stored.
    func store(certificate: HMAccessCertificate) {
        HMStorage.shared.storeCertificate(certificate)
    }
}

extension HMLocalDevice {

    var isEncryptionEnabled: Bool {
        configuration.isEncryptionEnabled
    }


    // MARK: Methods

    func changeState(to state: HMLocalDeviceState) {
        let oldState = self.state

        guard state != oldState else {
            return
        }

        self.state = state

        log("state changed 📯: \(state)",
            "old: \(oldState)",
            types: [.general, .bluetooth])

        // Send the update to the delegate too
        OperationQueue.main.addOperation {
            self.delegate?.localDevice(stateChanged: state, oldState: oldState)
        }
    }

    func linkCreated(_ link: HMLink) {
        // Send the update to the delegate
        OperationQueue.main.addOperation {
            self.delegate?.localDevice(didReceiveLink: link)
        }
    }

    func linkRemoved(_ link: HMLink) {
        // Send the update to the delegate
        OperationQueue.main.addOperation {
            self.delegate?.localDevice(didLoseLink: link)
        }
    }
}

private extension HMLocalDevice {

    func advertismentData(for certificate: HMDeviceCertificate, configuration: HMLocalDeviceConfiguration) throws -> Data {
        if let filter = configuration.broadcastingFilter {
            guard filter.count == 9 else {
                throw HMLocalDeviceError.invalidInput
            }

            log("starting advertisment 📡",
                "name: \(name)",
                "filter: \(filter.hex)",
                "serial: \(certificate.serial.hex)",
                types: .bluetooth)

            let zeros4 = [UInt8](repeating: 0x00, count: 4)
            let zeros3 = [UInt8](repeating: 0x00, count: 3)

            return (zeros4 + filter + zeros3).reversed().data
        }
        else {
            log("starting advertisment 📡",
                "name: \(name)",
                "issuer: \(certificate.issuer.hex)",
                "appID: \(certificate.appIdentifier.hex)",
                "serial: \(certificate.serial.hex)",
                types: .bluetooth)

            return (certificate.issuer + certificate.appIdentifier).reversed().data
        }
    }
}
