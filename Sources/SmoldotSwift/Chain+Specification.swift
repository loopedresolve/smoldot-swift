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
