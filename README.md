# HMKit iOS SDK

The HMKit iOS SDK makes it easy to work with car data using the *HIGH MOBILITY API* platform. The SDK implements a strong security layer between your iOS app and the platform while giving you straightforward native interface to read and write to connected cars.  
In addition the SDK provides a UI component to initate OAuth2 for the end-user in order to retrieve data sharing consent.

Table of contents
=================
<!--ts-->
   * [Features](#features)
   * [Integration](#integration)
   * [Requirements](#requirements)
   * [Getting Started](#getting-started)
      * [Examples](#examples)
   * [Contributing](#contributing)
   * [Licence](#licence)
<!--te-->


## Features

**Simple**: The library is designed to give iOS developers simple access to High Mobility's systems, by handling all the communication protocols, authentication flows and other security related components.

**Secure**: The SDK is a part of a *Public Key Infrastructure* (PKI) system, that enables secure communications in an open medium. Example  of another PKI system would be the Estonian digital ID-card with it's authentication and signing capabilities.

**Certificates**: Access certificates can be securely [downloaded](https://high-mobility.com/learn/documentation/mobile-sdks/ios/telematics/telematics/#download-ac) from High Mobility using an access token or OAuth. The certificates are stored on the device's *Keychain* encrypted and unaccesable while the device is locked.

**ECC**: Elliptic Curve Cryptography *p256* curve from [HMCryptoKit](https://github.com/highmobility/hmcryptokit-swift) is used to secure the connections in a small form factor (compared to RSA). Each piece of data you send, or receive, is encrypted and signed to avoid snooping and changes to the package.

**OAuth**: The SDK supports connecting to vehicle portals through [OAuth](https://high-mobility.com/learn/documentation/mobile-sdks/ios/oauth/oauth/) for connecting to a user's vehicle and accessing it's data.


## Integration

It's **recommended** to use the library through *Swift Package Manager* (SPM), which is now also built-in to Xcode and accessible in `File > Swift Packages > ...` or  going to project settings and selecting `Swift Packages` in the top-center.  
When targeting a Swift package, the `Package.swift` file must include `.package(url: "https://github.com/highmobility/hmkit-swift", .upToNextMinor(from: "[__version__]")),` under *dependencies*.
  

If SPM is not possible, the source can be downloaded directly from Github
and built into an `.xcframework` using an accompaning script: [XCFrameworkBuilder.sh](https://github.com/highmobility/hmkit-swift/tree/master/Scripts/XCFrameworkBuilder.sh). The created package includes both the simulator and device binaries, which must then be dropped (linked) to the target Xcode project.

Furthermore, when `.xcframework` is also not suitable, the library can be made into a *fat binary* (`.framework`) by running [UniversalBuildScript.sh](https://github.com/highmobility/hmkit-swift/tree/master/Scripts/UniversalBuildScript.sh). This combines both simulator and device slices into one binary, but requires the simulator slice to be removed *before* being able to upload to *App Store Connect* – for this there is a [AppStoreCompatible.sh](https://github.com/highmobility/hmkit-swift/tree/master/Scripts/AppStoreCompatible.sh) script included inside the created `.framework` folder.


> If **BLE** is used, the `NSBluetoothPeripheralUsageDescription` needs to be added to your app's `*.plist` with a description.

## Requirements

HMKit iOS SDK requires Xcode 11.0 or later and is compatible with apps targeting iOS 10.0 or above.


## Getting started

Get started by reading the [iOS guide](https://high-mobility.com/learn/tutorials/sdk/ios/) in high-mobility.com.  
Check out the [code references](https://high-mobility.com/learn/documentation/mobile-sdks/ios/local-device/local-device/) for more details than present in code documentation.

### Examples

There are 3 sample apps available on Github.com to showcase different use-cases for HMKit:

- [Scaffold](https://github.com/highmobility/hm-ios-scaffold) 
  - Demonstrates the most basic implementation to use HMKit.
- [Data Viewer](https://github.com/highmobility/hm-ios-data-viewer)
  -  Showcases simple HMKit's usage with both BLE and Telematics along with High Mobility's unified car-data protocol [AutoAPI](https://high-mobility.com/learn/tutorials/getting-started/auto-api-guide/).
- [AutoAPI Explorer](https://github.com/highmobility/hm-ios-auto-api-explorer)
  - Incorporates all the "abilities" of the previous sample apps along with more commands to send to the vehicle and takes a shot at a nice(r) UI.


## Contributing

We would love to accept your patches and contributions to this project. Before getting to work, please first discuss the changes that you wish to make with us via [GitHub Issues](https://github.com/highmobility/hmkit-swift/issues), [Spectrum](https://spectrum.chat/high-mobility/) or [Slack](https://slack.high-mobility.com/).

To start developing HMKit, please run `git clone git@github.com:highmobility/hmkit-swift.git` and open the Xcode project (Xcode will handle the dependencies itself). Releases are done by tagged commits (as required by SPM, please read more [here](https://swift.org/getting-started/#using-the-package-manager) and [here](https://github.com/apple/swift-package-manager/tree/master/Documentation)).

See more in [CONTRIBUTING.md](https://github.com/highmobility/hmkit-swift/tree/master/CONTRIBUTING.md)


## Licence

This repository is using MIT licence. See more in [LICENCE](https://github.com/highmobility/hmkit-swift/blob/master/LICENSE)
