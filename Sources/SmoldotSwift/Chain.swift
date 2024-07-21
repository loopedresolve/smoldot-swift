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

/// A model representing a Polkadot-based blockchain network.
///
public final class Chain: Hashable {
    
    internal var id: Id?
    public var specification: Specification
    
    /// Chain Id
    ///
    ///  A Chain Id represents a connection in the client.
    ///  
    internal typealias Id = Int
    
    ///  Chain Specification.
    ///
    ///  A Chain Specification is the collection of information that describes a Polkadot-based blockchain
    ///  network. For example, the chain specification identifies the network that a blockchain node
    ///  connects to, the other nodes that it initially communicates with, and the initial state that nodes
    ///  must agree on to produce blocks.
    ///
    ///  A typelias is used rather than defining an explicit type so that Foundation `JSONSerialization` 
    ///  can be used to convert the JSON into a `Dictionary` type representation of the object with key
    ///  values  of type `Any`.
    ///
    ///  - Important:
    ///  Niether the validity of the Chain Specification JSON nor its conformance to the ChainSpec trait
    ///  is handled by Swift and will produce fatal error information in the Rust environment logger.
    ///
    public typealias Specification = JSONObject
    
    ///  Creates a Chain from the a Chain Specification JSON object.
    ///
    ///  See ``Specification`` for more information.
    ///
    public init(specification: Specification) {
        self.specification = specification
    }
    
    ///  Creates a Chain from a Chain Specification JSON file.
    public convenience init(specificationFile url: URL) throws {
        let data = try Data(contentsOf: url)
        let specification = try JSONSerialization.jsonObject(with: data) as! Specification
        self.init(specification: specification)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(specification.id)
    }
    
    public static func == (lhs: Chain, rhs: Chain) -> Bool {
        return lhs.specification.id == rhs.specification.id
    }
}
