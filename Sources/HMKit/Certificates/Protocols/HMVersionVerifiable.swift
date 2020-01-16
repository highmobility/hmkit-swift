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
//  UInt8Collection+VersionVerifiable.swift
//  HMKit
//
//  Created by Mikk Rätsep on 25/10/2017.
//

import Foundation


enum HMVersionVerifiable {
    case accessCertificate(HMAccessCertificate.Version)
    case deviceCertificate(HMDeviceCertificate.Version)


    var versionValue: UInt8? {
        switch self {
        case .accessCertificate(let version):   return version.value
        case .deviceCertificate(let version):   return version.value
        }
    }
}


extension Collection where Element == UInt8 {

    func isVersion(_ verifiable: HMVersionVerifiable) -> Bool {
        switch verifiable {
        case .accessCertificate(let version):
            guard count >= version.minimumTotal else {
                return false
            }

            let permissionsSize = bytes[version.permissionIndex].int

            guard (0...16).contains(permissionsSize) else {
                return false
            }

            let sizeWithPermissions = version.minimumTotal + permissionsSize

            guard count == sizeWithPermissions else {
                return false
            }

        case .deviceCertificate(let version):
            guard count == version.total else {
                return false
            }
        }

        // Finally, verify the potential VERSION byte
        if let versionValue = verifiable.versionValue {
            guard first == versionValue else {
                return false
            }
        }

        // All checks out
        return true
    }
}
