// SmoldotSwift
// Copyright 2024 Finsig LLC
// SPDX-License-Identifier: Apache-2.0

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import CSmoldot
import JSONRPC2

/// A client that is used to connect to Polkadot-based blockchain networks.
///
public final class Client {
   
    /// The shared singleton client object.
    ///
    /// For basic requests, the Client class provides a shared singleton client object. Use the shared client to connect to Polkadot-based blockchain networks and send requests.
    ///
    /// The default client used is [smoldot](https://github.com/smol-dot/smoldot), an alternative client of Substrate-based chains, including Polkadot.
    ///
    public class var shared: Client {
        return Client()
    }
    
    private init() {
        let _ = Client.rustEnvironmentLogger
    }
    
    /// Rust Environment Logger
    ///
    /// Uses the Rust `env_logger` framework. Logging levels may be set accordingly. For example, `RUST_LOG=info`
    ///
    /// See [env_logger](https://docs.rs/env_logger/latest/env_logger/index.html) for more information.
    ///
    static let rustEnvironmentLogger: () = {
        if let level = ProcessInfo.processInfo.environment["RUST_LOG"] {
            smoldot_env_logger(level)
        }
    }()
    
    /// Add a Chain to the Client.
    ///
    public func add(chain: inout Chain) throws {
        guard !chain.isValid else {
            throw ClientError(message: "Chain has already been added.")
        }
        guard let data = try? JSONSerialization.data(withJSONObject: chain.specification) else {
            throw ClientError(message: "Invalid JSON object.") /// note: checks for validity only, does not check Chain Specification JSON object correctness. intentional.
        }
        let string = String(data: data, encoding: .utf8)
        chain.id = Chain.Id( smoldot_add_chain(string) )
    }
    
    /// Remove a Chain from the Client.
    ///
    public func remove(chain: inout Chain) throws {
        guard let id = chain.id else {
            throw ClientError(message: "Chain not found in client.")
        }
        smoldot_remove_chain(id)
    }
    
    /// Send a request to a Chain.
    ///
    ///  - Parameter request: A JSONRPC2Request object.
    ///  - Parameter to: The chain to send the request to.
    ///
    /// See ``JSONRPC2Request`` for more information.
    ///
    public func send(request: JSONRPC2Request, to chain: Chain) throws {
        guard let id = chain.id else {
            throw ClientError(message: "Chain not found in client.")
        }
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ClientError(message: "Error encoding request.")
        }
        smoldot_json_rpc_request(id, string)
    }
    
    /// Delivers a stream of string format JSON responses asynchronously.
    ///
    /// - Parameter chain: The chain to deliver responses from.
    /// - Parameter bufferingPolicy:A strategy that handles exhaustion of the stream buffer capacity.
    ///
    /// - Returns: A stream of asynchronously-delivered chain response strings.
    ///
    /// - Throws: An error if the specified chain is not found in the client.
    ///
    public func responses(from chain: Chain, bufferingPolicy: AsyncThrowingStream<String, Error>.Continuation.BufferingPolicy = .unbounded) -> AsyncThrowingStream<String, Error> {
        
        AsyncThrowingStream<String,Error>(String.self, bufferingPolicy: bufferingPolicy, { continuation in
            Task.detached {
                while (true) {
                    guard let id = chain.id else {
                        throw ClientError(message: "Chain not found in client.")
                    }
                    guard let cString = smoldot_wait_next_json_rpc_response(id) else {
                        break
                    }
                    let string = String(cString: cString)
                    smoldot_next_json_rpc_response_free(cString)
                    continuation.yield(string)
                }
                continuation.finish()
            }
        })
    }
    
    /// Delivers a  string format JSON response asynchronously.
    ///
    /// - Parameter chain: The chain to get a response from.
    ///
    /// - Returns: An asynchronously-delivered chain response string.
    ///
    /// - Throws: An error if the specified chain is not found in the client.
    ///
    public func response(from chain: Chain) async throws -> String? {
        guard let id = chain.id else {
            throw ClientError(message: "Chain not found in client.")
        }
        guard let cString = smoldot_wait_next_json_rpc_response(id) else {
           return nil
        }
        let string = String(cString: cString)
        smoldot_next_json_rpc_response_free(cString)
        return string
    }
}


internal extension Chain {
    var isValid: Bool {
        guard let id else {
            return false
        }
        return smoldot_is_valid_chain_id(id)
    }
}
