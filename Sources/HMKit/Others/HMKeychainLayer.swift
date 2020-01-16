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
//  HMKeychainLayer.swift
//  HMKit
//
//  Created by Mikk Rätsep on 20/06/2017.
//

import CoreFoundation
import Foundation
import Security


struct HMKeychainLayer {

    static var shared = HMKeychainLayer()


    // MARK: iVars

    var privateKey: Data? {
        set {
            saveData(newValue, for: .key(isPrivateKey: true))
        }
        get {
            return loadData(for: .key(isPrivateKey: true))
        }
    }

    var publicKey: Data? {
        set {
            saveData(newValue, for: .key(isPrivateKey: false))
        }
        get {
            return loadData(for: .key(isPrivateKey: false))
        }
    }


    // MARK: Methods

    func loadData(for label: String) -> Data? {
        return loadData(for: .data(label: label))
    }

    func saveData(_ data: Data?, label: String) {
        saveData(data, for: .data(label: label))
    }


    private init() { }
}

private extension HMKeychainLayer {

    enum KeychainDataType {
        case data(label: String)
        case key(isPrivateKey: Bool)
    }


    typealias KeychainDictionary = [AnyHashable : Any]


    // MARK: Methods

    func deleteEverything() {
        let classes = [kSecClassCertificate, kSecClassGenericPassword, kSecClassIdentity, kSecClassInternetPassword, kSecClassKey]

        classes.forEach {
            let query = [(kSecClass as AnyHashable): $0]

            SecItemDelete(query as NSDictionary)
        }
    }

    func keychainDict(for type: KeychainDataType) -> KeychainDictionary {
        var dict: KeychainDictionary = [:]

        switch type {
        case .data(let label):
            dict[kSecClass as AnyHashable] = kSecClassGenericPassword
            dict[kSecAttrAccessible as AnyHashable] = kSecAttrAccessibleAfterFirstUnlock
            dict[kSecAttrAccount as AnyHashable] = label
            dict[kSecAttrService as AnyHashable] = label

        case .key(let isPrivateKey):
            dict[kSecClass as AnyHashable] = kSecClassKey
            dict[kSecAttrAccessible as AnyHashable] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            dict[kSecAttrKeyClass as AnyHashable] = isPrivateKey ? kSecAttrKeyClassPrivate : kSecAttrKeyClassPublic
            dict[kSecAttrLabel as AnyHashable] = "HMKit " + (isPrivateKey ? "Private" : "Public") + " Key"
        }

        return dict
    }

    func loadData(for type: KeychainDataType) -> Data? {
        var data: Data?
        var dataRef: AnyObject?
        var dict = keychainDict(for: type)

        dict[kSecReturnData as AnyHashable] = kCFBooleanTrue
        dict[kSecMatchLimit as AnyHashable] = kSecMatchLimitOne

        if SecItemCopyMatching((dict as NSDictionary), &dataRef) == noErr {
            if let resultRef = dataRef {
                data = resultRef as? Data
            }
        }

        return data
    }

    func saveData(_ data: Data?, for type: KeychainDataType) {
        var dict = keychainDict(for: type)

        // Delete the old entry
        SecItemDelete(dict as NSDictionary)

        // And save a new one, if the data wasn't nil
        if let data = data {
            dict[kSecValueData as AnyHashable] = data

            SecItemAdd((dict as NSDictionary), nil)
        }
    }
}
