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
//  HMBluetooth.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/11/2018.
//

import CoreBluetooth
import Foundation


class HMBluetooth: NSObject {

    private(set) var links: Set<HMLink>

    // Bluetooth values //
    private var peripheralManager: CBPeripheralManager
    private var service: CBMutableService

    private var aliveCharacteristic: CBMutableCharacteristic
    private var infoCharacteristic: CBMutableCharacteristic

    private var incomingReadCharacteristic: CBMutableCharacteristic
    private var incomingWriteCharacteristic: CBMutableCharacteristic
    private var outgoingReadCharacteristic: CBMutableCharacteristic
    private var outgoingWriteCharacteristic: CBMutableCharacteristic

    private var incomingReadData: Data? = nil
    private var outgoingReadData: Data? = nil

    // Others //
    private var alivePingTimer: Timer?
    private var retryValues: HMPeripheralRetryValues?
    private var servicesAdded: Bool = false
    private var startAdvertisingOptions: [String : Any]?


    // MARK: Type Methods

    static func cbUUID(from id: String) -> CBUUID {
        CBUUID(string: "713D01\(id)-503E-4C75-BA94-3148F18D941E")
    }


    // MARK: Init

    override init() {
        links = Set<HMLink>()

        // Init the peripheral manager
        peripheralManager = CBPeripheralManager(delegate: nil,  // Delegate gets set after super.init()
                                                queue: DispatchQueue(label: "hmkit.peripheralManager", qos: .utility),
                                                options:  [CBPeripheralManagerOptionShowPowerAlertKey : false])

        // Init the service
        service = CBMutableService(type: HMService.primary.cbUUID, primary: true)

        // Init the characteristics
        aliveCharacteristic = CBMutableCharacteristic(characteristic: .alive)
        infoCharacteristic = CBMutableCharacteristic(characteristic: .info)

        incomingReadCharacteristic = CBMutableCharacteristic(characteristic: .incomingRead)
        incomingWriteCharacteristic = CBMutableCharacteristic(characteristic: .incomingWrite)
        outgoingReadCharacteristic = CBMutableCharacteristic(characteristic: .outgoingRead)
        outgoingWriteCharacteristic = CBMutableCharacteristic(characteristic: .outgoingWrite)

        // Add characterstics to the service
        service.characteristics = [aliveCharacteristic,
                                   infoCharacteristic,
                                   incomingReadCharacteristic,
                                   incomingWriteCharacteristic,
                                   outgoingReadCharacteristic,
                                   outgoingWriteCharacteristic]

        // Initialise the stupid NSObject
        super.init()

        // Now we can use self as well
        peripheralManager.delegate = self
    }
}

extension HMBluetooth: CBPeripheralManagerDelegate {

    // MARK: CBPeripheralManagerDelegate

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            guard !peripheral.isAdvertising else {  // TODO: is this even possible?
                return
            }

            changeState(to: .idle)
        }
        else {
            changeState(to: .bluetoothUnavailable)

            // Remove all links
            links.forEach { self.removeLink(with: $0.central) }
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error == nil {
            changeState(to: .broadcasting)
        }
        else if let error = error as? CBError {
            guard error.code != .alreadyAdvertising else {
                return
            }

            changeState(to: .idle)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil,
            let options = startAdvertisingOptions else {
                return
        }

        // Simply call the -startAdvertisment flow again
        peripheral.startAdvertising(options)
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard let values = retryValues else {
            return
        }

        // Remove the "used" values
        retryValues = nil

        // Send the update
        update(characteristic: values.characteristic, with: values.bytes, for: values.link)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        log("subscribed 🔔 to characteristic: \(characteristic.uuid.uuidString)", types: [.bluetooth, .maidu])

        // Request a "better" connection latency
        peripheralManager.setDesiredConnectionLatency(.low, for: central)

        // And create the link (the method updates the HMLocalDevice too) etc.
        createLink(with: central)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        // Disconnect the link
        if let link = link(for: central) {
            log("unsubscribed 🔕 to characteristic: \(characteristic.uuid.uuidString)", types: [.bluetooth, .maidu])

            link.disconnect()
        }
        else {
            log("unknown central: \(central.identifier.uuidString)",
                "unsubscribed 🔕 to characteristic: \(characteristic.uuid.uuidString)",
                types: [.bluetooth, .maidu])
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        let data: Data?
        let name: String

        // Find out what characteristic the read was performed on
        switch request.characteristic {
        case incomingReadCharacteristic:
            data = incomingReadData
            name = "incoming 📲"

        case outgoingReadCharacteristic:
            data = outgoingReadData
            name = "outgoing 📤"

        case aliveCharacteristic:
            // Just empty value for the alive-ping
            data = Data()
            name = "alive"

        case infoCharacteristic:
            data = infoCharacteristicData()
            name = "info"

        default:
            log("receiveRead on \"invalid\" characteristic",
                "uuid: \(request.characteristic.uuid.uuidString)",
                types: [.bluetooth, .maidu])

            // Exit the scope by responding with a failure
            return peripheral.respond(to: request, withResult: .requestNotSupported)
        }

        // Only allow "proper" reads pass through.
        guard let value = data else {
            log("receiveRead on \"\(name)\" which has no data", types: [.bluetooth, .maidu, .error])

            // And exit the scope by responding with a failure
            return peripheral.respond(to: request, withResult: .readNotPermitted)
        }

        // Set the request's value to reflect it's offset
        request.value = value[request.offset ..< value.count]

        // Respond to the request – that it's all fine and nice and it can read from this
        peripheral.respond(to: request, withResult: .success)

        /*
         Check if the read is complete and we should notify the "user"
         */
        switch request.characteristic {
        case incomingReadCharacteristic, outgoingReadCharacteristic:
            // The +2 is some sort of ATT protocol header (maybe)
            let totalRead = request.offset + request.central.maximumUpdateValueLength + 2

            // If all the data has been read or not
            if totalRead >= value.count {
                guard let link = link(for: request.central) else {
                    return log("failed to find an HMLink for uuid: \(request.central.identifier.uuidString)", types: [.bluetooth, .error, .maidu])
                }

                log("receivedRead on \(name) characteristic",
                    "offset: \(request.offset)",
                    "final block 🏁",
                    "data: \(value.hex) (\(value.count) bytes)",
                    types: [.bluetooth, .maidu])

                link.readCompleted()
            }
            else {
                log("receivedRead on \(name) characteristic",
                    "offset: \(request.offset)",
                    "read size: \(request.central.maximumUpdateValueLength + 2)",
                    "data: \(value.hex) (\(value.count) bytes)",
                    types: [.bluetooth, .maidu])
            }

        default:
            // Do nothing for others
            break
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            let characteristic: HMCharacteristic
            let name: String

            switch request.characteristic {
            case incomingWriteCharacteristic:
                characteristic = .incomingWrite
                name = "incoming 📲"

            case outgoingWriteCharacteristic:
                characteristic = .outgoingWrite
                name = "outgoing 📤"

            default:
                log("receivedWrite on \"invalid\" characteristic",
                    "uuid: \(request.characteristic.uuid.uuidString)",
                    types: [.bluetooth, .maidu])

                // Respond to the request with a failure
                peripheral.respond(to: request, withResult: .writeNotPermitted)

                // Continue to the next request
                continue
            }

            // Check if there was any data actually sent
            guard let data = request.value, data.count > 0 else {
                log("receivedWrite on \(name) characteristic",
                    "without any data",
                    types: [.bluetooth, .maidu])

                // Respond to the request with a failure
                peripheral.respond(to: request, withResult: .unlikelyError)

                // Continue to the next request
                continue
            }

            log("receivedWrite on \(name) characteristic",
                "data: \(data.hex) (\(data.count) bytes)",
                types: [.bluetooth, .maidu])

            // Respond to the request with a success
            peripheral.respond(to: request, withResult: .success)

            // Send the received data to the link
            received(data: data, on: characteristic, from: request.central)
        }
    }
}

extension HMBluetooth {

    var error: HMBluetoothError? {
        switch peripheralManager.state {
            case .poweredOff:   return .poweredOff
            case .unauthorized: return .unauthorised
            case .unsupported:  return .unsupported

            default:
                return nil
        }
    }

    var isAdvertising: Bool {
        peripheralManager.isAdvertising
    }


    // MARK: Methods

    func disconnect() {
        stopAdvertising()

        links.forEach {
            $0.disconnect()
        }

        wipeServices()
        stopAlivePing()
    }

    func checkAlivePingState() {
        if isAlivePingEnabled {
            // If it's active - don't restart it
            guard alivePingTimer == nil else {
                return
            }

            alivePingTimer = Timer.scheduledTimer(withTimeInterval: HMTimeouts.alivePing.rawValue, repeats: true) { _ in
                // Check if the ALIVE PING is activated, if not – stop the repeating timer.
                guard self.isAlivePingEnabled, self.servicesAdded else {
                    return self.stopAlivePing()
                }

                let payload = [0x01].data

                // Update the characteristic on ALL connected devices
                self.peripheralManager.updateValue(payload, for: self.aliveCharacteristic, onSubscribedCentrals: nil)
            }

            // Activate it
            alivePingTimer?.fire()
        }
        else {
            stopAlivePing()
        }
    }

    func removeLink(with central: CBCentral) {
        guard let removedLink = link(for: central) else {
            return log("no HMLink found to remove",
                       "for central: \(central.identifier.uuidString)",
                types: [.bluetooth, .error, .maidu])
        }

        // Remove the link from the list
        links.remove(removedLink)

        // Send the update(s) to the HMLocalDevice too (so it could update the dev)
        HMLocalDevice.shared.linkRemoved(removedLink)
    }

    func startAdvertising(options: [String : Any]) {
        startAdvertisingOptions = options

        guard peripheralManager.state == .poweredOn else {
            return
        }

        // Check services
        if servicesAdded {
            peripheralManager.startAdvertising(options)
        }
        else {
            servicesAdded = true

            peripheralManager.add(service)
        }
    }

    func stopAdvertising() {
        startAdvertisingOptions = nil

        peripheralManager.stopAdvertising()
    }

    func update(characteristic: HMCharacteristic, with bytes: [UInt8], for link: HMLink) {
        // TODO: Might want to wait for retry values, if they are waiting themselves

        let cbCharacteristic: CBMutableCharacteristic
        let formattedData = HMParser.protocolFormattedBytes(from: bytes).data
        let name = (characteristic == .incomingRead) ? "incoming 📲" : "outgoing 📤"

        if characteristic == .incomingRead {
            incomingReadData = formattedData
            cbCharacteristic = incomingReadCharacteristic
        }
        else if characteristic == .outgoingRead {
            outgoingReadData = formattedData
            cbCharacteristic = outgoingReadCharacteristic
        }
        else {
            return
        }

        // Update the characteristic
        if peripheralManager.updateValue(formattedData, for: cbCharacteristic, onSubscribedCentrals: [link.central]) {
            log("updateRead on \(name) characteristic",
                "data: \(bytes.hex) (\(bytes.count) bytes)",
                types: [.maidu, .bluetooth])
        }
        else {
            // Set retry values
            retryValues = HMPeripheralRetryValues(bytes: bytes, characteristic: characteristic, link: link)

            log("updateRead on \(name) characteristic",
                "queue full ❗️",
                "waiting for ready",
                types: [.maidu, .bluetooth])
        }
    }
}

private extension HMBluetooth {

    var isAlivePingEnabled: Bool {
        guard HMLocalDevice.shared.certificate != nil,
            HMLocalDevice.shared.configuration.isAlivePingActive else {
                return false
        }

        return links.contains { ($0.state == .authenticated) || ($0.state == .connected) }
    }


    // MARK: Private Methods

    func changeState(to state: HMLocalDeviceState) {
        HMLocalDevice.shared.changeState(to: state)
    }

    /// Also sends the created `HMLink` to the `HMLocalDevice`.
    func createLink(with central: CBCentral) {
        guard self.link(for: central) == nil else {
            return
        }

        let link = HMLink(central: central)

        links.insert(link)

        // Send the update to the HMLocalDevice too (so it could update the "user")
        HMLocalDevice.shared.linkCreated(link)
    }

    func infoCharacteristicData() -> Data? {
        var string = "iOS"

        // Get the HMLocalDevice's version
        if let version = Bundle(for: HMLocalDevice.self).infoDictionary?["CFBundleShortVersionString"] as? String {
            string += " \(version) m"
        }
        else {
            string += " 3.x.x m"
        }

        // Finds the smalles MTU
        if let smallestMTU = links.map({ $0.central.maximumUpdateValueLength }).min() {
            string += " MTU" + String(format: "%03d", smallestMTU)
        }

        // Get the string's data
        guard let value = string.data(using: .utf8) else {
            return nil
        }

        return value
    }

    func link(for central: CBCentral) -> HMLink? {
        return links.first { $0.central == central }
    }

    func received(data: Data, on characteristic: HMCharacteristic, from central: CBCentral) {
        guard let link = link(for: central) else {
            return log("couldn't find an HMLink for received data",
                       "for central: \(central.identifier.uuidString)",
                        types: [.bluetooth, .error, .maidu])
        }

        link.received(data: data, on: characteristic)
    }

    func stopAlivePing() {
        alivePingTimer?.invalidate()
        alivePingTimer = nil
    }

    func wipeServices() {
        peripheralManager.removeAllServices()
        servicesAdded = false

        incomingReadData = nil
        outgoingReadData = nil

        // Wipe the characteristics (just in case...)
        aliveCharacteristic.value = nil
        infoCharacteristic.value = nil
        incomingReadCharacteristic.value = nil
        incomingWriteCharacteristic.value = nil
        outgoingReadCharacteristic.value = nil
        outgoingWriteCharacteristic.value = nil
    }
}
