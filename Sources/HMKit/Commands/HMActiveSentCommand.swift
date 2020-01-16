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
//  HMActiveSentCommand.swift
//  HMKit
//
//  Created by Mikk Rätsep on 14/12/2018.
//

import Foundation


class HMActiveSentCommand {

    private let completion: HMLinkCommandCompletionBlock
    private let timeoutTimer: Timer?


    // MARK: Init

    init(completion: @escaping HMLinkCommandCompletionBlock) {
        self.completion = completion

        // Start the timeout timer
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: HMTimeouts.command.rawValue, repeats: false) { timer in
            // This is maybe useless here
            timer.invalidate()

            // Finally call the block
            completion(.failure(.timeOut))
        }
    }

    deinit {
        timeoutTimer?.invalidate()
    }
}

extension HMActiveSentCommand {

    var isFinished: Bool {
        guard let timer = timeoutTimer else {
            return true
        }

        return !timer.isValid
    }


    // MARK: Methods

    func complete(with result: Result<Void, HMLinkError>) {
        guard !isFinished else {
            return
        }

        // Invalidate the timeout timer too
        timeoutTimer?.invalidate()

        // Finally call the block
        completion(result)
    }
}
