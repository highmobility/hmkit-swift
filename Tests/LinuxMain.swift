//
// HMKitTests
// Copyright (C) 2018 High-Mobility GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//
// Please inquire about commercial licensing options at
// licensing@high-mobility.com
//

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
// Hello my darling
#else
import XCTest
import HMKitTests

XCTMain([
    testCase(AccessCertificateTests.allTests),
    testCase(DeviceCertificateTests.allTests),

    testCase(AuthenticateCommandTests.allTests),
    testCase(AuthenticateDoneCommandTests.allTests),
    testCase(GetCertificateCommandTests.allTests),
    testCase(GetDeviceCertificateCommandTests.allTests),
    testCase(NonceCommandTests.allTests),
    testCase(RegisterCertificateCommandTests.allTests),
    testCase(ResetCommandTests.allTests),
    testCase(RevokeCommandTests.allTests),
    testCase(SecureContainerCommandTests.allTests),
    testCase(StoreCertificateCommandTests.allTests),
])
#endif
