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
//  HMTelematics.swift
//  HMKit
//
//  Created by Mikk Rätsep on 14/02/2017.
//

import Foundation
import HMCryptoKit


public typealias HMTelematicsResult<Success> = Result<Success, HMTelematicsError>
public typealias HMTelematicsResultBlock<Success> = (HMTelematicsResult<Success>) -> Void
public typealias HMTelematicsRequestSuccess = (response: [UInt8], contentType: HMContainerContentType, requestID: [UInt8])


public class HMTelematics {

    /// `OptionSet` that configures the type of logs printed to the console; defaults to `.general`.
    ///
    /// - seeAlso: `LoggingOptions`
    public static var loggingOptions: HMLoggingOptions = [.general] {
        didSet {
            HMLoggingOptions.activeOptions = loggingOptions
        }
    }

    /// The URL base used in Telematics' and Access Certificate requests.
    public static var urlBasePath = HMTelematicsAPI.Base.test.rawValue


    // MARK: Methods

    /// Download `HMAccessCertificate` for the *accessToken*.
    ///
    /// - parameters:
    ///   - accessToken: Access token received through vehicle owner's authorisation.
    ///   - completion: Block that returns, `HMTelematicsResult<[UInt8]>`, target vehicle's serial number or failure.
    /// - throws:
    ///   - `HMCryptoKitError`-s
    ///   - `HMTelematicsError`-s
    ///   - `JSONEncoder` errors
    public class func downloadAccessCertificate(accessToken: String, completionWithSerial completion: @escaping HMTelematicsResultBlock<[UInt8]>) throws {
        guard let privateKey = HMLocalDevice.shared.privateKey,
            let serialNumber = HMLocalDevice.shared.serial else {
                throw HMTelematicsError.localDeviceUninitialised
        }

        let request = try HMTelematicsAccessCertificateRequest(accessToken: accessToken, serial: serialNumber, privateKey: privateKey)

        try request.sendRequest {
            switch $0 {
            case .failure(let failure):
                completion(.failure(failure))

            case .success(let response):
                HMStorage.shared.storeCertificate(response.device)

                if let vehicleCert = response.vehicle {
                    HMStorage.shared.storeCertificate(vehicleCert)
                }

                completion(.success(response.device.gainingSerial))
            }
        }
    }

    /// Convenience method for checking if the `HMAccessCertificate`-s database has a matching certificate.
    ///
    /// The matching `HMAccessCertificate`'s *gaining* serial number is that of the input.
    /// Also, the *providing* serial number must match `HMLocalDevice`'s serial number.
    ///
    /// Generic input can be for an example `[UInt8]` or `Data`.
    ///
    /// - parameters:
    ///     - serial: Serial number of the *other* device; must be **9 bytes**.
    /// - returns: `true` if there is a matching (authorised) `HMAccessCertificate`.
    /// - throws:
    ///     `.invalidData` when the serial number is of wrong size.
    ///     `.localDeviceUninitialised` when the `HMLocalDevice` is missing it's `HMDeviceCertificate`.
    public class func isAuthorisedToVehicle<C: Collection>(serial: C) throws -> Bool where C.Iterator.Element == UInt8 {
        guard serial.count == 9 else {
            throw HMTelematicsError.invalidData
        }

        guard let deviceSerial = HMLocalDevice.shared.serial else {
            throw HMTelematicsError.localDeviceUninitialised
        }

        return HMStorage.shared.certificates.contains {
            ($0.gainingSerial == serial.bytes) && ($0.providingSerial == deviceSerial)
        }
    }

    /// Send a command to a vehicle through the internet.
    ///
    /// Generic input can be for an example `[UInt8]` or `Data`.
    ///
    /// - parameters:
    ///   - command: Bytes-collection that will be sent inside the secure container.
    ///   - contentType: Type of data sent as content, *defaults* to `.autoAPI`.
    ///   - requestID: ID to keep track of a specific command (response will contain the same ID).
    ///   - serial: Target vehicle's (or charger's) serial number; must be **9 bytes**.
    ///   - completion: Block that returns `HMTelematicsResult<HMTelematicsRequestSuccess>` with an error or the response data (and other info) for the command.
    /// - throws:
    ///   - `HMCryptoKitError`-s
    ///   - `HMTelematicsError`-s
    ///   - `HMProtocolError`-s
    ///   - `JSONEncoder` errors
    public class func sendCommand<C: Collection>(_ command: C,
                                                 contentType: HMContainerContentType = .autoAPI,
                                                 requestID: [UInt8] = [],
                                                 serial: [UInt8],
                                                 completionWithResponse completion: @escaping HMTelematicsResultBlock<HMTelematicsRequestSuccess>) throws where C.Iterator.Element == UInt8 {
        guard serial.count == 9 else {
            throw HMTelematicsError.invalidData
        }

        try downloadNonce {
            switch $0 {
            case .failure(let failure):
                completion(.failure(failure))

            case .success(let nonce):
                do {
                    try sendTelematicsCommand(command.bytes,
                                              contentType: contentType,
                                              nonce: nonce,
                                              requestID: requestID,
                                              serial: serial,
                                              completion: completion)
                }
                catch let error as HMTelematicsError {
                    completion(.failure(error))
                }
                catch {
                    completion(.failure(.misc(error)))
                }
            }
        }
    }


    // MARK: Private

    private init() { }
}

extension HMTelematics {

    class func updateBasePath(from deviceCertificate: HMDeviceCertificate) {
        // Try to create a string from the issuer-bytes.
        // And match the name to known ones.
        guard let name = String(bytes: deviceCertificate.issuer, encoding: .utf8),
            let urlBase = HMTelematicsAPI.Base(rawValue: name) else {
                return
        }

        // And set
        urlBasePath = urlBase.rawValue
    }
}

private extension HMTelematics {

    class func downloadNonce(completion: @escaping HMTelematicsResultBlock<[UInt8]>) throws {
        guard let deviceSerial = HMLocalDevice.shared.serial else {
            throw HMTelematicsError.localDeviceUninitialised
        }

        try HMTelematicsNonceRequest(serial: deviceSerial).sendRequest {
            switch $0 {
            case .failure(let failure):
                completion(.failure(failure))

            case .success(let response):
                completion(.success(response.nonce))
            }
        }
    }

    class func sendTelematicsCommand(_ command: [UInt8],
                                     contentType: HMContainerContentType,
                                     nonce: [UInt8],
                                     requestID: [UInt8],
                                     serial: [UInt8],
                                     completion: @escaping HMTelematicsResultBlock<HMTelematicsRequestSuccess>) throws {
        guard let deviceSerial = HMLocalDevice.shared.serial else {
            throw HMTelematicsError.localDeviceUninitialised
        }

        guard let accessCertificate = HMStorage.shared.certificates(withGainingSerial: serial).first(where: { $0.providingSerial == deviceSerial }) else {
            throw HMTelematicsError.invalidData
        }

        let request = try HMTelematicsCommandRequest(command: command,
                                                     contentType: contentType,
                                                     nonce: nonce,
                                                     requestID: requestID,
                                                     serial: serial,
                                                     accessCertificate: accessCertificate)

        try request.sendRequest {
            switch $0 {
            case .failure(let failure):
                completion(.failure(failure))

            case .success(let response):
                let success = HMTelematicsRequestSuccess(response: response.container.command,
                                                         contentType: response.container.contentType,
                                                         requestID: response.container.requestID)

                completion(.success(success))
            }
        }
    }
}
