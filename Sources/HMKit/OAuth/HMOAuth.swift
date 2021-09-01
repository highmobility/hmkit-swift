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
//  HMOAuth.swift
//  HMKit
//
//  Created by Mikk Rätsep on 30/10/2018.
//


import HMCryptoKit
import SafariServices

#if !os(macOS)
import UIKit
#endif


public typealias HMOAuthResult = Result<HMOAuthSuccess, HMOAuthFailure>


public class HMOAuth {

    /// The *singleton* access to the OAuth.
    public static let shared = HMOAuth()

    public private(set) var appID: String!
    public private(set) var authURI: String!
    public private(set) var clientID: String!
    public private(set) var redirectScheme: String!
    public private(set) var tokenURI: String!
    public private(set) var state: String?
    public private(set) var validity: HMPeriod?

    /// If the `SFSafariViewController` presentation and dismissal is *animated*.
    ///
    /// Defaults to `true`.
    public var animate: Bool = true

    private var handler: ((HMOAuthResult) -> Void)?
    #if !os(macOS)
    private var safari: SFSafariViewController?
    #endif

    private var nonce: [UInt8]?


    // MARK: Methods

    /// Verifies the callback to either extract the *error*
    /// or the *code* for getting the **access token**.
    ///
    /// The *result* is returned through `-launchAuthFlow`'s `handler` parameter.
    /// Also dismisses the *Safari* controller.
    ///
    /// - Parameter url: The URL received in `AppDelegate`'s `-application(_:open:options:)` method.
    ///
    /// - Returns: `true` if the *url* is meant for `HMOAuth`.
    @discardableResult public func handleCallback(with url: URL) -> Bool {
        // Dismiss the Safari view
        #if !os(macOS)
        safari?.dismiss(animated: animate, completion: nil)
        #endif

        // Check if the URL is meant for us
        guard url.absoluteString.hasPrefix(redirectScheme) else {
            return false
        }

        // Try to get query items
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            handler?(.failure(HMOAuthFailure(reason: .invalidURL)))

            return true
        }

        // Extract the "state" if present
        let stateValue = queryItems.first { $0.name == "state" }?.value

        // Extract the "error" or the "accessCode"
        if let errorValue = queryItems.first(where: { $0.name == "error" })?.value {
            log("received error: \(errorValue)", types: [.oauth, .error])

            handler?(.failure(HMOAuthFailure(reason: .accessDenied)))
        }
        else if let codeValue = queryItems.first(where: { $0.name == "code" })?.value {
            requestAccessToken(code: codeValue, state: stateValue, grantType: .authorisationCode)
        }
        else {
            handler?(.failure(HMOAuthFailure(reason: .missingToken)))
        }

        return true
    }

    /// Request a new *access token* with a previously received *refresh token*.
    ///
    /// The *result* is returned through `-launchAuthFlow`'s `handler` parameter.
    ///
    /// - Parameters:
    ///   - refreshToken: The *refresh token* received after initial authentication.
    ///   - state: Optional String, used as *context* to differentiate.
    public func requestAccessToken(refreshToken: String, state: String?) {
        requestAccessToken(code: refreshToken, state: state, grantType: .refreshToken)
    }

    #if !os(macOS)
    /// Start the OAuth flow with all the required values.
    ///
    /// If the *access token* is received successfully,
    /// it should be passed on to `HMTelematics.downloadAccessCertificate`.
    ///
    /// - Parameters:
    ///   - appID: Application's identifier.
    ///   - authURI: The base *authentication* URI.
    ///   - clientID: Client identifier.
    ///   - redirectScheme: The URI used to redirect back to the app.
    ///   - tokenURI: Where the *access token* is requested from.
    ///   - state: Optional String, used as *context* to differentiate.
    ///   - validity: Optional HMPeriod of the resulting *Access Certificates*.
    ///   - viewController: The `UIViewController` to present the *Safari view* from.
    ///   - handler: Callback to handle the *authentication* and *access token* results.
    public func launchAuthFlow(appID: String,
                               authURI: String,
                               clientID: String,
                               redirectScheme: String,
                               tokenURI: String,
                               state: String? = nil,
                               validity: HMPeriod? = nil,
                               for viewController: UIViewController,
                               handler: @escaping (HMOAuthResult) -> Void) {
        self.appID = appID
        self.authURI = authURI
        self.clientID = clientID
        self.redirectScheme = redirectScheme
        self.state = state
        self.tokenURI = tokenURI
        self.validity = validity
        self.handler = handler

        do {
            let url = try oauthURL(authURI: authURI, state: state, validity: validity)

            safari = SFSafariViewController(url: url)

            if #available(iOS 11.0, *) {
                safari?.dismissButtonStyle = .cancel
            }

            // Finally display the webpage
            viewController.present(safari!, animated: animate, completion: nil)

        }
        catch let failure as HMOAuthFailure {
            handler(.failure(failure))
        }
        catch {
            handler(.failure(HMOAuthFailure(reason: .internalError, state: state)))
        }
    }
    #endif

    #if os(macOS)
    public func launchAuthFlow(appID: String,
                               authURI: String,
                               clientID: String,
                               redirectScheme: String,
                               tokenURI: String,
                               state: String? = nil,
                               validity: HMPeriod? = nil,
                               handler: @escaping (HMOAuthResult) -> Void) {
        self.appID = appID
        self.authURI = authURI
        self.clientID = clientID
        self.redirectScheme = redirectScheme
        self.state = state
        self.tokenURI = tokenURI
        self.validity = validity
        self.handler = handler

        do {
            _ = try oauthURL(authURI: authURI, state: state, validity: validity)

            // TODO: do smth here
        }
        catch let failure as HMOAuthFailure {
            handler(.failure(failure))
        }
        catch {
            handler(.failure(HMOAuthFailure(reason: .internalError, state: state)))
        }
    }
    #endif


    #if !os(macOS)
    /// Alternative method to start the OAuth flow with all the required
    /// and optional values.
    ///
    /// If the *access token* is received successfully,
    /// it should be passed on to `HMTelematics.downloadAccessCertificate`.
    ///
    /// - Parameters:
    ///   - requiredValues: The minimum required values for the authentication.
    ///   - optionalValues: Optional values for the authentication.
    ///   - viewController: The `UIViewController` to present the *Safari view* from.
    ///   - handler: Callback to handle the *authentication* and *access token* results.
    ///
    /// - SeeAlso: `launchAuthFlow(appID:authURI:clientID:redirectScheme:scope:tokenURI:state:validity:for:handler:)`
    public func launchAuthFlow(requiredValues: HMOAuthRequiredValues,
                               optionalValues: HMOAuthOptionalValues?,
                               for viewController: UIViewController,
                               handler: @escaping (HMOAuthResult) -> Void) {
        launchAuthFlow(appID: requiredValues.appID,
                       authURI: requiredValues.authURI,
                       clientID: requiredValues.clientID,
                       redirectScheme: requiredValues.redirectScheme,
                       tokenURI: requiredValues.tokenURI,
                       state: optionalValues?.state,
                       validity: optionalValues?.validity,
                       for: viewController,
                       handler: handler)
    }
    #endif

    #if os(macOS)
    public func launchAuthFlow(requiredValues: HMOAuthRequiredValues,
                               optionalValues: HMOAuthOptionalValues?,
                               handler: @escaping (HMOAuthResult) -> Void) {
        launchAuthFlow(appID: requiredValues.appID,
                       authURI: requiredValues.authURI,
                       clientID: requiredValues.clientID,
                       redirectScheme: requiredValues.redirectScheme,
                       tokenURI: requiredValues.tokenURI,
                       state: optionalValues?.state,
                       validity: optionalValues?.validity,
                       handler: handler)
    }
    #endif


    // MARK: Init

    private init() {

    }
}

private extension HMOAuth {

    func oauthURL(authURI: String, state: String?, validity: HMPeriod?) throws -> URL {
        var queryItems: [URLQueryItem] = []
        let nonce = try HMCryptoKit.randomBytes(9)

        guard let nonceData = "\(nonce.hex.uppercased())".data(using: .ascii) else {
            throw HMOAuthFailure(reason: .internalError, state: state)
        }

        let nonceSHA256 = try HMCryptoKit.sha256(message: nonceData)
        let codeChallenge = nonceSHA256.data.base64URLEncodedString()

        // Add the "mandatory" items
        queryItems.append(URLQueryItem(name: "code_challenge", value: codeChallenge.urlQueryPercentEncoded))
        queryItems.append(URLQueryItem(name: "client_id", value: clientID.urlQueryPercentEncoded))
        queryItems.append(URLQueryItem(name: "redirect_uri", value: redirectScheme.urlQueryPercentEncoded))
        queryItems.append(URLQueryItem(name: "app_id", value: appID.urlQueryPercentEncoded))

        // And the optional items
        if let state = state {
            queryItems.append(URLQueryItem(name: "state", value: state.urlQueryPercentEncoded))
        }

        if let validity = validity {
            let formatter = ISO8601DateFormatter()

            queryItems.append(URLQueryItem(name: "validity_start_date", value: formatter.string(from: validity.start).urlQueryPercentEncoded))
            queryItems.append(URLQueryItem(name: "validity_end_date", value: formatter.string(from: validity.end).urlQueryPercentEncoded))
        }

        // Generate the URL
        guard var components = URLComponents(string: authURI) else {
            throw HMOAuthFailure(reason: .internalError, state: state)
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw HMOAuthFailure(reason: HMOAuthFailure.Reason.invalidURL, state: state)
        }

        // Update the internal nonce
        self.nonce = nonce

        // Output
        return url
    }

    func requestAccessToken(code: String, state: String?, grantType: HMOAuthGrantType) {
        // Get the "handler"
        guard let handler = handler else {
            return
        }

        // Create the URL
        guard let url = URL(string: tokenURI) else {
            return handler(.failure(HMOAuthFailure(reason: .invalidURL, state: state)))
        }

        // Create the body
        let body: Data

        do {
            body = try tokenBody(code: code, grantType: grantType, state: state)
        }
        catch let failure as HMOAuthFailure {
            return handler(.failure(failure))
        }
        catch {
            return handler(.failure(HMOAuthFailure(reason: .internalError, state: state)))
        }

        // Initialise the request
        let request = URLRequest(url: url,
                                 httpMethod: "POST",
                                 body: body,
                                 headers: ["Content-Type" : "application/json"])

        log("requesting ACCESS TOKEN...",
            "type: \(grantType)",
            types: [.oauth])

        // Send out and parse the "access token" request
        URLSession.shared.dataTask(with: request) { data, response, error in
            // If there was a "standard" error
            guard error == nil else {
                log("token response error: \(error!)", types: [.error, .oauth])

                return handler(.failure(HMOAuthFailure(reason: .accessDenied, state: state)))
            }

            // Get the data
            guard let data = data else {
                log("token response has no data", types: [.error, .oauth])

                return handler(.failure(HMOAuthFailure(reason: .missingToken, state: state)))
            }

            // Extract the JSON
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                log("failed to create JSON from: \(data.hex)", types: [.error, .oauth])

                return handler(.failure(HMOAuthFailure(reason: .missingToken, state: state)))
            }

            // Check if the server returned an error
            if let error = json["error"] as? String,
                let errorDesc = json["error_description"] as? String {
                log("error getting Access Token",
                    "error: \(error)",
                    "description: \(errorDesc)",
                    types: [.error, .oauth])

                return handler(.failure(HMOAuthFailure(reason: .accessDenied, state: state)))
            }

            // And the "access token"
            guard let accessToken = json["access_token"] as? String,
                let refreshToken = json["refresh_token"] as? String,
                let expiresIn = json["expires_in"] as? Double else {
                    log("missing token(s)",
                        "json: \(json)",
                        types: [.error, .oauth])

                    return handler(.failure(HMOAuthFailure(reason: .missingToken, state: state)))
            }

            // Happiness
            handler(.success(HMOAuthSuccess(accessToken: accessToken, expiresIn: expiresIn, refreshToken: refreshToken, state: state)))
        }.resume()
    }

    func tokenBody(code: String, grantType: HMOAuthGrantType, state: String?) throws -> Data {
        // Combine the JSON
        var json = ["client_id": clientID.urlQueryPercentEncoded,
                    "grant_type": grantType.rawValue.urlQueryPercentEncoded]

        switch grantType {
        case .authorisationCode:
            // Get the "initialised" required values
            guard let privateKey = HMLocalDevice.shared.privateKey,
                let serial = HMLocalDevice.shared.serial else {
                    throw HMOAuthFailure(reason: .localDeviceUninitialised, state: state)
            }

            // Check the nonce's presence
            guard let nonce = nonce else {
                throw HMOAuthFailure(reason: .internalError, state: state)
            }

            // Create the header and payload
            let headerDict = ["alg": "ES256", "typ": "JWT"]
            let payloadDict = ["serial_number": serial.hex.uppercased(), "code_verifier": nonce.hex.uppercased()]

            // Convert the header and payload to base64URLEncoded strings
            let headerB64 = try JSONEncoder().encode(headerDict).base64URLEncodedString()
            let payloadB64 = try JSONEncoder().encode(payloadDict).base64URLEncodedString()

            // Create the combined message
            let message = headerB64 + "." + payloadB64

            // Get the bytes for the combined message
            guard let messageData = message.data(using: .utf8) else {
                throw HMOAuthFailure(reason: .internalError, state: state)
            }

            // Create the signature and the final "jwt result"
            let signature = try HMCryptoKit.signature(message: messageData, privateKey: privateKey, padded: false)
            let signatureB64 = signature.data.base64URLEncodedString()
            let codeVerifier = message + "." + signatureB64

            // Add the remaining required fields
            json["code"] = code.urlQueryPercentEncoded
            json["code_verifier"] = codeVerifier.urlQueryPercentEncoded
            json["redirect_uri"] = redirectScheme.urlQueryPercentEncoded

        case .refreshToken:
            // Add the refresh_token field
            json["refresh_token"] = code.urlQueryPercentEncoded
        }

        return try JSONEncoder().encode(json)
    }
}
