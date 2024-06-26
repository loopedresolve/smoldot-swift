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
    public static var polkadot: Chain {
        return Chain(resourceName: "polkadot")
    }
    public static var kusama: Chain {
        return Chain(resourceName: "kusama")
    }
    public static var rococo: Chain {
        return Chain(resourceName: "rococo")
    }
    public static var westend: Chain {
        return Chain(resourceName: "westend")
    }
}


fileprivate extension Chain {
    convenience init(resourceName name: String) {
        guard let fileURL = Bundle.module.url(forResource: name, withExtension: "json") else {
            fatalError()
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            fatalError()
        }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? JSONObject else {
            fatalError()
        }
        self.init(specification: jsonObject)
    }
}
