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
//  HMCharacteristic.swift
//  HMKit
//
//  Created by Mikk Rätsep on 05/11/2018.
//

import CoreBluetooth
import Foundation


enum HMCharacteristic {

    case outgoingRead
    case outgoingWrite

    case alive
    case info

    case incomingRead
    case incomingWrite


    // MARK: Vars

    var permissions: CBAttributePermissions {
        switch self {
        case .outgoingRead:     return .readable
        case .outgoingWrite:    return .writeable

        case .alive:            return .readable
        case .info:             return .readable

        case .incomingRead:     return .readable
        case .incomingWrite:    return .writeable
        }
    }

    var properties: CBCharacteristicProperties {
        switch self {
        case .outgoingRead:     return [.read, .notify]
        case .outgoingWrite:    return .write

        case .alive:            return [.read, .notify]
        case .info:             return .read

        case .incomingRead:     return [.read, .notify]
        case .incomingWrite:    return .write
        }
    }

    var cbUUID: CBUUID {
        let id: String

        switch self {
        case .outgoingRead:     id = "02"
        case .outgoingWrite:    id = "03"

        case .alive:            id = "04"
        case .info:             id = "05"

        case .incomingRead:     id = "06"
        case .incomingWrite:    id = "07"
        }

        return HMBluetooth.cbUUID(from: id)
    }

    var isOutgoing: Bool {
        switch self {
        case .outgoingRead, .outgoingWrite:
            return true

        default:
            return false
        }
    }
}


extension CBMutableCharacteristic {

    convenience init(characteristic: HMCharacteristic) {
        self.init(type: characteristic.cbUUID,
                  properties: characteristic.properties,
                  value: nil,
                  permissions: characteristic.permissions)
    }
}
