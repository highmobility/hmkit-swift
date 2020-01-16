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
//  HMLink.swift
//  HMKit
//
//  Created by Mikk Rätsep on 06/11/2018.
//

import CoreBluetooth
import Foundation
import HMCryptoKit


public typealias HMLinkCommandCompletionBlock = (Result<Void, HMLinkError>) -> Void


public class HMLink {

    /// Object that conforms to `HMLinkDelegate` for callback from the `HMLink`.
    public var delegate: HMLinkDelegate?


    /// The `HMAccessCertificate` used with this link when *authorised*, read-only.
    public private(set) var certificate: HMAccessCertificate?

    /// State of the `HMLink`, read-only.
    ///
    /// Changes are sent to the `delegate` as well.
    ///
    /// - SeeAlso: `HMLinkDelegate`
    public private(set) var state: HMLinkState


    private(set) var central: CBCentral

    private var activeSentCommand: HMActiveSentCommand?
    private var parser: HMParser
    private var previousGeneratedNonce: [UInt8]?
    private var readCompletion: HMReadCompletionBlock?
    private var sessionKey: HMSessionKey?


    // MARK: Init

    init(central: CBCentral) {
        self.central = central

        // Created when a connection has been made – meaning it starts being connected
        state = .connected

        parser = HMParser()
        parser.delegate = self
    }
}

public extension HMLink {

    /// Disconnects the `HMLink`.
    func disconnect() {
        // Update the link's status for when the dev kept a reference to it.
        changeState(to: .disconnected)

        HMLocalDevice.shared.bluetooth.removeLink(with: central)
    }

    /// Send command to the connected device inside a secure container.
    ///
    /// Generic input can be for an example `[UInt8]` or `Data`.
    ///
    /// - Parameters:
    ///   - command: The data to send to the connected device.
    ///   - contentType: Type of data sent as content, *defaults* to `.autoAPI`.
    ///   - requestID: ID to keep track of a specific command (response will contain the same ID).
    ///   - completion: Block that gets called with `Result<Void, HMLinkError>` when this command is done.
    ///
    /// - Throws:
    ///   - `unauthorised` when the connection has not been *authenticated*.
    ///   - `commandInProgress` when a previous command has not finished yet.
    ///   - `commandTooBig` when the command is bigger than version's max size (`.v1 == UInt16.max` or `.v2 == UInt32.max`).
    ///   - `HMCryptoKitError` when HMAC creation had errors.
    func send<C: Collection>(command: C, contentType: HMContainerContentType = .autoAPI, requestID: [UInt8] = [], completion: @escaping HMLinkCommandCompletionBlock) throws where C.Element == UInt8 {
        // Needs to be authorised to send messages
        guard let sessionKey = authenticatedSessionKey else {
            throw HMLinkError.unauthorised
        }

        // Check if there's a command in progress
        guard activeSentCommand == nil else {
            throw HMLinkError.commandInProgress
        }

        // Use the correct version of the container
        let version: HMSecureContainerCommandVersion

        switch HMLocalDevice.shared.configuration.containerVersion {
        case .one:  version = .one
        case .two:  version = .two(contentType: contentType, requestID: requestID)
        }

        // Check the command's size
        guard command.count <= version.maxSize else {
            throw HMLinkError.commandTooBig
        }

        let request = try HMSecureContainerCommandRequest(command: command.bytes,
                                                          sessionKey: sessionKey.localSessionKey,
                                                          version: version)

        log("📜 \(HMProtocolCommand.secContainer)", types: .command)

        // "Activate" an activeSentCommand (it has a timeout timer also)
        activeSentCommand = HMActiveSentCommand(completion: completion)

        // Send the command
        try send(on: .outgoingRead, bytes: request.bytes) { }
    }

    /// Send the *revoke* command to the connected device.
    ///
    /// After the revoke is received by the connected device,
    /// a *disconnect* is executed by it, to reset the connection.
    ///
    /// - Throws: `unauthorised` when the connection is not *authenticated*.
    func sendRevoke() throws {
        // Needs to be authorised to send messages
        guard let sessionKey = authenticatedSessionKey,
            let serial = certificate?.providingSerial else {
                throw HMLinkError.unauthorised
        }

        // TODO: Not sure if we should wait for a SecureContainer response
        // Check if there's a command in progress
        guard activeSentCommand == nil else {
            throw HMLinkError.commandInProgress
        }

        let request = try HMRevokeCommandRequest(serial: serial, sessionKey: sessionKey.localSessionKey)

        // Send the command
        try send(on: .outgoingRead, bytes: request.bytes) { }
    }
}

extension HMLink: Equatable {

    public static func ==(lhs: HMLink, rhs: HMLink) -> Bool {
        return lhs.central == rhs.central
    }
}

extension HMLink: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(central)
    }
}

extension HMLink: HMParserDelegate {

    func parser(_ parser: HMParser, didReadCompletePackage bytes: [UInt8], isOutgoing: Bool) {
        do {
            var resolvedBytes = bytes

            // Decrypt the bytes if required
            if (state == .authenticated) && HMLocalDevice.shared.isEncryptionEnabled {
                resolvedBytes = try decryptBytes(bytes, isOutgoing: isOutgoing)

                log("data 📲🔐 IN: \(bytes.hex) (\(bytes.count) bytes)", types: [.bluetooth, .encryption])
            }

            log("data 📲 IN: \(resolvedBytes.hex) (\(resolvedBytes.count) bytes)", types: .bluetooth)

            resolveReceivedCommand(bytes: resolvedBytes, isOutgoing: isOutgoing)
        }
        catch let error as HMProtocolError {
            errorReceived(error)
        }
        catch {
            print("parser didReadCompletePackage error:", error)
        }
    }
}

extension HMLink {

    func readCompleted() {
        // Completes the 'readCompletion' block when sending out data
        readCompletion?()
        readCompletion = nil
    }

    func received(data: Data, on characteristic: HMCharacteristic) {
        parser.parseIncoming(binary: data, characteristic: characteristic)
    }
}

private extension HMLink {

    typealias HMReadCompletionBlock = () -> Void


    var authenticationNonce: HMSessionKey.Nonce? {
        return sessionKey?.originalNonce
    }

    var authenticatedSessionKey: HMSessionKey? {
        guard state == .authenticated else {
            return nil
        }

        return sessionKey
    }


    // MARK: Methods

    func completeActiveSentCommand(with result: Result<Void, HMLinkError>) {
        // Complete the "command-sent-completion" block
        activeSentCommand?.complete(with: result)
        activeSentCommand = nil
    }

    func deauthenticate() {
        certificate = nil
        sessionKey = nil

        changeState(to: .connected)
    }

    func decryptBytes(_ bytes: [UInt8], isOutgoing: Bool) throws -> [UInt8] {
        guard let sessionKey = sessionKey else {
            throw HMLinkError.unauthorised
        }

        // isOutgoing means we're sending, meaning we need to use the local session key
        return try sessionKey.encryptDecrypt(bytes, useLocalSessionKey: isOutgoing)
    }

    func resolveReceivedCommand(bytes: [UInt8], isOutgoing: Bool) {
        do {
            if isOutgoing {
                switch try HMCommandResponseFactory.create(fromBytes: bytes) {
                case let response as HMSecureContainerCommandResponse:
                    try handleSecureContainer(response: response)

                case let response as HMRevokeCommandResponse:
                    handleRevoke(response: response)

                default:
                    throw HMLinkError.internalError
                }
            }
            else {
                switch try HMCommandRequestFactory.create(fromBytes: bytes) {
                case let request as HMGetNonceCommandRequest:
                    try handleNonce(request: request)

                case let request as HMGetDeviceCertificateCommandRequest:
                    try handleGetDeviceCertificate(request: request)

                case let request as HMRegisterCertificateCommandRequest:
                    try handleRegisterCertificate(request: request)

                case let request as HMAuthenticateCommandRequest:
                    try handleAuthenticate(request: request)

                case let request as HMAuthenticateDoneCommandRequest:
                    try handleAuthenticationDone(request: request)

                case let request as HMGetAccessCertificateCommandRequest:
                    try handleGetAccessCertificate(request: request)

                case let request as HMRevokeCommandRequest:
                    try handleRevoke(request: request)

                case let request as HMSecureContainerCommandRequest:
                    try handleSecureContainer(request: request)

                case let request as HMErrorCommandRequest:
                    try handleError(request: request)

                default:
                    throw HMLinkError.internalError
                }
            }
        }
        catch {
            print("resolveReceivedCommand error:", error)
        }
    }


    // MARK: Delegate Methods

    func authorisationRequested(by serial: [UInt8], approvalBlock: @escaping () throws -> Void) {
        // Send the update to the delegate
        OperationQueue.main.addOperation {
            self.delegate?.link(self,
                                authorisationRequestedBy: serial,
                                approve: approvalBlock,
                                timeout: HMTimeouts.register.rawValue)
        }
    }

    func changeState(to state: HMLinkState) {
        let oldState = self.state

        guard state != oldState else {
            return
        }

        self.state = state

        log("link: \(central.identifier.uuidString)",
            "state changed 📯: \(state)",
            "old: \(oldState)",
            types: [.general, .bluetooth])

        // Send the update to the delegate
        OperationQueue.main.addOperation {
            self.delegate?.link(self, stateChanged: state, previousState: oldState)
        }

        // Check if the alivePing needs to be activated or not
        HMLocalDevice.shared.bluetooth.checkAlivePingState()
    }

    func commandReceived(bytes: [UInt8], contentType: HMContainerContentType, requestID: [UInt8]) {
        // Send the update to the delegate
        OperationQueue.main.addOperation {
            self.delegate?.link(self, commandReceived: bytes, contentType: contentType, requestID: requestID)
        }
    }

    func errorReceived(_ error: HMProtocolError) {
        // Send the update to the delegate
        OperationQueue.main.addOperation {
            self.delegate?.link(self, receivedError: error)
        }
    }

    func revokeCompleted(with bytes: [UInt8]) {
        // Send the update to the delegate
        OperationQueue.main.addOperation {
            self.delegate?.link(self, revokeCompleted: bytes)
        }
    }


    // MARK: Sending Methods

    func send(on characteristic: HMCharacteristic, bytes: [UInt8], readCompletion: @escaping HMReadCompletionBlock) throws {
        var bytes = bytes

        log("data 📤 OUT: \(bytes.hex) (\(bytes.count) bytes)", types: .bluetooth)

        if (state == .authenticated) && HMLocalDevice.shared.isEncryptionEnabled {
            bytes = try decryptBytes(bytes, isOutgoing: characteristic.isOutgoing)

            log("data 📤🔐 OUT: \(bytes.hex) (\(bytes.count) bytes)", types: [.bluetooth, .encryption])
        }

        self.readCompletion = readCompletion

        // Send the update to HMBluetooth (that does the actual sending/updating)
        HMLocalDevice.shared.bluetooth.update(characteristic: characteristic, with: bytes, for: self)
    }

    func sendResponse(_ response: HMCommandResponse, readCompletion: @escaping HMReadCompletionBlock) throws {
        try send(on: .incomingRead, bytes: response.bytes, readCompletion: readCompletion)
    }

    func sendError(_ error: HMProtocolError, for request: HMCommandRequest, readCompletion: @escaping HMReadCompletionBlock) throws {
        let message = [HMCommandResponseType.error.rawValue, request.type.rawValue, error.rawValue]

        log("\(type(of: request)) \(error)", types: [.error, .bluetooth])

        try send(on: .incomingRead, bytes: message, readCompletion: readCompletion)
    }


    // MARK: Command Handling Methods

    func handleAuthenticate(request: HMAuthenticateCommandRequest) throws {
        guard state != .authenticated else {
            return try sendError(.internalError, for: request) { }
        }

        // Get the appropriate certificates
        let certificates = HMStorage.shared.certificates(withGainingSerial: request.serial)

        guard certificates.count > 0 else {
            return try sendError(.internalError, for: request) { }
        }

        // Find the valid certificate
        let firstCertificate = try certificates.first {
            guard let publicKey = $0.gainingPublicKeyECKey else {
                return false
            }

            return try request.isSignatureValid(forKey: publicKey)
        }

        guard let certificate = firstCertificate else {
            return try sendError(.invalidSignature, for: request) { }
        }

        // Get the keys
        guard let privateKey = HMLocalDevice.shared.privateKey else {
            return try sendError(.internalError, for: request) { }
        }

        // Create response values
        let nonce = try HMCryptoKit.nonce()
        let gainingPublicKey = try HMCryptoKit.publicKey(binary: certificate.gainingPublicKey)
        let sessionKey = try HMSessionKey(privateKey: privateKey, otherPublicKey: gainingPublicKey, nonce: nonce)
        let response = try HMAuthenticateCommandResponse(privateKey: privateKey, nonce: nonce)

        // Update the "conf" before responding
        self.certificate = certificate
        self.sessionKey = sessionKey

        // Send back the ACK
        try sendResponse(response) { }
    }

    func handleAuthenticationDone(request: HMAuthenticateDoneCommandRequest) throws {
        guard state != .authenticated else {
            return try sendError(.internalError, for: request) { }
        }

        // Gather some values
        guard let certificate = certificate,
            let nonce = authenticationNonce else {
                return try sendError(.internalError, for: request) { }
        }

        // Check that the nonces match
        guard nonce == request.nonce else {
            return try sendError(.internalError, for: request) { }
        }

        let gainingPublicKey = try HMCryptoKit.publicKey(binary: certificate.gainingPublicKey)

        // Check the signature
        guard try request.isSignatureValid(forKey: gainingPublicKey) else {
            return try sendError(.invalidSignature, for: request) { }
        }

        let response = try HMAuthenticateDoneCommandResponse()

        // Send back the ACK
        try sendResponse(response) {
            // On Maidu's recommendation.
            // Because in Chrome there might be a race-condition between different characteristics...
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.changeState(to: .authenticated)
            }
        }
    }

    func handleGetAccessCertificate(request: HMGetAccessCertificateCommandRequest) throws {
        // Find certificates
        guard let registeredCert = HMStorage.shared.certificate(withGainingSerial: request.serial),
            let storedCert = HMStorage.shared.certificate(withProvidingSerial: request.serial) else {
                return try sendError(.invalidData, for: request) { }
        }

        let gainingPublicKey = try HMCryptoKit.publicKey(binary: registeredCert.gainingPublicKey)

        // Check the signature
        guard try request.isSignatureValid(forKey: gainingPublicKey) else {
            return try sendError(.invalidSignature, for: request) { }
        }

        let response = try HMGetAccessCertificateCommandResponse(accessCertificate: storedCert)

        // Send back the ACK
        try sendResponse(response) {
            // Used to have: Storage.shared.deleteCertificateWithProvidingSerial(storedCert.providingSerial)
        }
    }

    func handleGetDeviceCertificate(request: HMGetDeviceCertificateCommandRequest) throws {
        // If the request has a nonce
        if !request.nonce.isZeroNonce {
            // Check if the nonce in the request is the latest this device sent out
            guard let nonce = previousGeneratedNonce, nonce == request.nonce else {
                previousGeneratedNonce = nil

                return try sendError(.internalError, for: request) { }
            }
        }

        // Check the signaturre
        guard try request.isSignatureValid(forKey: HMLocalDevice.shared.issuerPublicKey) else {
            if !request.nonce.isZeroNonce {
                previousGeneratedNonce = nil
            }

            return try sendError(.invalidSignature, for: request) { }
        }

        // Get the deviceCertificate
        guard let certificate = HMLocalDevice.shared.certificate else {
            return try sendError(.internalError, for: request) { }
        }

        let response = try HMGetDeviceCertificateCommandResponse(deviceCertificate: certificate)

        // Send back the ACK
        try sendResponse(response) {
            self.previousGeneratedNonce = nil
        }
    }

    func handleNonce(request: HMCommandRequest) throws {
        let response = try HMGetNonceCommandResponse()

        // Send back the ACK
        try sendResponse(response) {
            self.previousGeneratedNonce = response.nonce
        }
    }

    func handleRegisterCertificate(request: HMRegisterCertificateCommandRequest) throws {
        var hasTimedOut = false

        // Block called when approved by the user/dev
        let approvalBlock: HMLinkDelegate.Approve = {
            // Check if the block has already timed out
            guard !hasTimedOut else {
                log("registerCertificate timeout", types: [.error, .command])

                throw HMLinkError.timeOut
            }

            // Gather some values
            guard let certificate = HMLocalDevice.shared.certificate else {
                return try self.sendError(.internalError, for: request) { }
            }

            let publicKey = try HMCryptoKit.publicKey(binary: certificate.publicKey)
            let response = try HMRegisterCertificateCommandResponse(publicKey: publicKey, privateKey: HMLocalDevice.shared.privateKey)

            // Send back the ACK
            try self.sendResponse(response) {
                // Register the certificate
                HMStorage.shared.storeCertificate(request.accessCertificate)
            }
        }

        authorisationRequested(by: request.accessCertificate.gainingSerial, approvalBlock: approvalBlock)

        // Start a 'timeout timer'
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + HMTimeouts.register.rawValue) {
            hasTimedOut = true
        }
    }

    func handleRevoke(request: HMRevokeCommandRequest) throws {
        // Check authorised status
        guard let sessionKey = authenticatedSessionKey else {
            return try sendError(.unauthorised, for: request) { }
        }

        // Check the signature
        guard try request.isSignatureValid(forKey: sessionKey.remoteSessionKey) else {
            return try sendError(.invalidHMAC, for: request) { }
        }

        // Delete the appropriate certificates
        guard let _ = HMStorage.shared.deleteCertificate(withSerial: request.serial, type: .gaining) else {
            return try sendError(.internalError, for: request) { }
        }

        HMStorage.shared.deleteCertificate(withSerial: request.serial, type: .providing)

        let response = try HMRevokeCommandResponse(responseBytes: [])   // Don't need to send any bytes back through Revoke (for now)

        // Send back the ACK
        try sendResponse(response) {
            guard request.serial == self.certificate?.gainingSerial else {
                return sessionKey.incrementRemote()
            }

            // Reset to connected state
            self.deauthenticate()
        }
    }

    func handleRevoke(response: HMRevokeCommandResponse) {
        // Delete the certificate if present
        if let certificate = certificate {
            HMStorage.shared.deleteCertificate(certificate)
        }

        deauthenticate()
        revokeCompleted(with: response.bytes)
    }

    func handleSecureContainer(request: HMSecureContainerCommandRequest) throws {
        // Check authorised status
        guard let sessionKey = authenticatedSessionKey else {
            return try sendError(.unauthorised, for: request) { }
        }

        // Check the signature
        guard try request.isSignatureValid(forKey: sessionKey.remoteSessionKey) else {
            return try sendError(.invalidHMAC, for: request) { }
        }

        // Gather some values
        let key = request.requiresHMAC ? sessionKey.remoteSessionKey : nil
        let response = try HMSecureContainerCommandResponse(response: [], sessionKey: key, version: request.version)    // We return an empty ACK with SecureContainer

        // Send back the ACK
        try sendResponse(response) {
            // After ack is read, increase the nonce and notify the delegate
            sessionKey.incrementRemote()
            self.commandReceived(bytes: request.command, contentType: request.contentType, requestID: request.requestID)
        }
    }

    func handleSecureContainer(response: HMSecureContainerCommandResponse) throws {
        // Check that we actually sent a command before we got a response
        guard activeSentCommand != nil else {
            throw HMLinkError.internalError
        }

        // Check the HMAC, if it's present
        if response.hmac != nil {
            // Session key is needed (must be authenticated)
            guard let sessionKey = authenticatedSessionKey else {
                log("no sessionKey", types: .error)

                return completeActiveSentCommand(with: .failure(.unauthorised))
            }

            // Check the HMAC
            guard try response.isSignatureValid(forKey: sessionKey.localSessionKey) else {
                return completeActiveSentCommand(with: .failure(.invalidSignature))
            }

            sessionKey.incrementLocal()
        }

        // If all good - complete the active command
        completeActiveSentCommand(with: .success(Void()))
    }

    func handleError(request: HMErrorCommandRequest) throws {
        let response = try HMErrorCommandResponse()

        // Send back an ACK
        try sendResponse(response) {
            self.errorReceived(request.error)
        }
    }
}
