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

extension Chain {
    
    ///  Chain Specification.
    ///
    ///  A Chain Specification is the collection of information that describes a Polkadot-based blockchain
    ///  network. For example, the chain specification identifies the network that a blockchain node
    ///  connects to, the other nodes that it initially communicates with, and the initial state that nodes
    ///  must agree on to produce blocks.
    ///
    ///  A typelias is used rather than defining an explicit type so that Foundation `JSONSerialization` can be
    ///  used to convert the JSON into a Foundation `Dictionary` type representation of the object where the
    ///  values of keys are of type `Any`.
    ///
    ///  Using `JSONSerialization` rather than `JSONDecode` provides flexibility in the structure of the
    ///  JSONObject. The correctness of the JSON is enforced at the FFI call site.
    ///
    public typealias Specification = JSONObject
}

#warning("TODO: revisit comments")

extension Chain.Specification {
    
    /// Guaranteed to exist in the JSON Object as it is a required method on the Rust ChainSpec trait.
    public var name: String {
        return self["name"] as! String
    }
    
    /// Guaranteed to exist in the JSON Object as it is a required method on the Rust ChainSpec trait.
    var id: String {
        return self["id"] as! String
    }
}
