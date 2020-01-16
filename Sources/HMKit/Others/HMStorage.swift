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
//  HMStorage.swift
//  HMKit
//
//  Created by Mikk Rätsep on 03/08/15.
//

import Foundation


class HMStorage {

    /// The singleton's access point for Storage class.
    static let shared = HMStorage()

    var serialNumber: [UInt8]!

    #if !PRODUCTION
    /// - warning: If *enabled* the **CERTIFICATES** are **stored in memory**.
    var isPlaygroundDatabaseEnabled: Bool = false

    private var playgroundDB: [HMAccessCertificate] = []
    #endif

    private let StorageKeyAllCertificates = "HMKit-StorageKeyAllCertificates"


    // MARK: Methods

    func resetStorage() {
        certificates = nil
    }

    func storeCertificate(_ certificate: HMAccessCertificate) {
        // Delete the old similar certificate(s)
        certificates.filter { $0 ~= certificate }.forEach { deleteCertificate($0) }

        // Add the new one
        certificates.append(certificate)
    }


    // MARK: Init

    private init() {
        
    }
}


// MARK: Computed Vars

extension HMStorage {

    var certificates: [HMAccessCertificate]! {
        get {
            #if !PRODUCTION
            guard !isPlaygroundDatabaseEnabled else {
                return playgroundDB
            }
            #endif

            guard let data = HMKeychainLayer.shared.loadData(for: StorageKeyAllCertificates) else {
                return []
            }

            do {
                return try JSONDecoder().decode([HMAccessCertificate].self, from: data)
            }
            catch {
                return []
            }
        }
        set {
            #if !PRODUCTION
            guard !isPlaygroundDatabaseEnabled else {
                playgroundDB = newValue
                return
            }
            #endif

            let data: Data?
            
            if newValue == nil {
                log("AccessCertificates storage reset", types: .general)
                
                data = nil
            }
            else {
                do {
                    data = try JSONEncoder().encode(newValue)
                }
                catch {
                    // Just bail
                    return log("Certificate storage fatal error:", types: .error)
                }
            }
            
            HMKeychainLayer.shared.saveData(data, label: StorageKeyAllCertificates)
        }
    }

    var registeredCertificates: [HMAccessCertificate] {
        return certificates.filter { $0.providingSerial == serialNumber }
    }

    var storedCertificates: [HMAccessCertificate] {
        return certificates.filter { $0.providingSerial != serialNumber }
    }
}


// MARK: Finding

extension HMStorage {

    func certificate<C: Collection>(withProvidingSerial serial: C) -> HMAccessCertificate? where C.Iterator.Element == UInt8 {
        return certificate { $0.providingSerial == serial.bytes }
    }

    func certificate<C: Collection>(withGainingSerial serial: C) -> HMAccessCertificate? where C.Iterator.Element == UInt8 {
        return certificate { $0.gainingSerial == serial.bytes }
    }

    func certificates<C: Collection>(withGainingSerial serial: C) -> [HMAccessCertificate] where C.Iterator.Element == UInt8 {
        return certificates.filter { $0.gainingSerial == serial.bytes }
    }
}

private extension HMStorage {

    func certificate(where filter: (HMAccessCertificate) -> Bool) -> HMAccessCertificate? {
        guard let certificates = self.certificates, certificates.count > 0 else {
            return nil
        }

        return certificates.first(where: filter)
    }
}


// MARK: Deleting

extension HMStorage {

    @discardableResult func deleteCertificate(_ certificate: HMAccessCertificate) -> HMAccessCertificate? {
        return deleteCertificate { $0 ~= certificate }
    }

    @discardableResult func deleteCertificate<C: Collection>(withSerial serial: C, type: HMSerialType) -> HMAccessCertificate? where C.Element == UInt8 {
        switch type {
        case .gaining:
            return deleteCertificate { $0.gainingSerial == serial.bytes }

        case .providing:
            return deleteCertificate { $0.providingSerial == serial.bytes}
        }
    }
}

private extension HMStorage {

    func deleteCertificate(where filter: (HMAccessCertificate) -> Bool) -> HMAccessCertificate? {
        guard certificates.count > 0 else {
            return nil
        }

        guard let idx = certificates.firstIndex(where: filter) else {
            return nil
        }

        return certificates.remove(at: idx)
    }
}
