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
//  HMTelematicsRequest.swift
//  HMKit
//
//  Created by Mikk Rätsep on 12/05/2019.
//

import Foundation


protocol HMTelematicsRequest: Encodable {

    associatedtype Response: HMTelematicsResponse


    var endpoint: HMTelematicsAPI.Endpoint { get }


    func sendRequest(completion: @escaping HMTelematicsResultBlock<Response>) throws
}

extension HMTelematicsRequest {

    func sendRequest(completion: @escaping HMTelematicsResultBlock<Response>) throws {
        guard let url = endpoint.url else {
            throw HMTelematicsError.invalidData
        }

        var request = URLRequest(url: url)

        request.httpBody = try JSONEncoder().encode(self)
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        log("request 📤 OUT",
            "encoding: 📜 \(type(of: self))",
            "url: \(url.absoluteString)",
            "headers: \(request.allHTTPHeaderFields!)",
            "body: \(request.httpBody!.jsonDict!)",
            types: [.telematics, .command])

        // Send the request to the ether
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                log("response 📲 IN",
                    "error #1: \(error)",
                    types: [.error, .telematics])

                return completion(.failure(.misc(error)))
            }

            guard let data = data else {
                log("response 📲 IN",
                    "error #2: missing data",
                    types: [.error, .telematics])

                return completion(.failure(.invalidData))
            }

            // Currently outputs only a single error
            if let error = try? JSONDecoder().decode(HMTelematicsResponseErrorsRoot.self, from: data).errors.first {
                log("response 📲 IN",
                    "error #3: \(error)",
                    types: [.error, .telematics])

                return completion(.failure(.response(error)))
            }

            // Finally try to decode the response
            do {
                log("response 📲 IN",
                    "decoding: 📜 \(Response.self)",
                    "data: \(data.hex)",
                    "json: \(data.jsonDict ?? [:])",
                    types: [.telematics, .command])

                let response = try JSONDecoder().decode(Response.self, from: data)

                completion(.success(response))
            }
            catch let error as HMTelematicsError {
                log("response 📲 IN",
                    "error #4: \(error)",
                    types: [.error, .telematics])
                completion(.failure(error))
            }
            catch {
                log("response 📲 IN",
                    "error #5: \(error)",
                    types: [.error, .telematics])
                completion(.failure(.misc(error)))
            }
        }.resume()
    }
}


private extension Data {

    var jsonDict: [String : String]? {
        guard let json = try? JSONSerialization.jsonObject(with: self, options: []) else {
            return nil
        }

        return json as? [String : String]
    }
}
