import XCTest
import JSON
import JSONRPC2
@testable import SmoldotSwift

final class SmoldotSwiftTests: XCTestCase {
    
    var chain: Chain!
    
    override func setUp() async throws {
        chain = Chain(specification: .polkadot)
    }
    
    func testAddChain() throws {
        try Client.shared.add(chain: &chain)
        
        XCTAssertTrue( chain.isValid )
    }
    
    func testAddChainAlreadyAdded() throws {
        try Client.shared.add(chain: &chain)
        
        XCTAssertThrowsError( try Client.shared.add(chain: &chain) )
    }
    
    /*
    func testAddChainRemoveChainMemoryPerformance() async throws {
        self.measure(metrics: [XCTMemoryMetric()]) {
            let exp = expectation(description: "Finished")
            Task {
                try Client.shared.add(chain: &chain)
                //try await Task.sleep(nanoseconds: 1_000_000_000 * 30) // sleep
                try Client.shared.remove(chain: &chain)
                //try await Task.sleep(nanoseconds: 1_000_000_000 * 30) // sleep
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1_000_000_000 * 30)
        }
    }
    */
    
    func testRemoveChain() throws {
        try Client.shared.add(chain: &chain)
        try Client.shared.remove(chain: &chain)
        
        XCTAssertFalse( chain.isValid )
    }
    
    func testRemoveChainNotAdded() throws {
        XCTAssertThrowsError( try Client.shared.remove(chain: &chain) )
    }
    
    func testJSONRPCRequestResponse() async throws {
        try Client.shared.add(chain: &chain)
        
        let request = try JSONRPC2Request(string: "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_chain\",\"params\":[]}")
        
        XCTAssertNoThrow( try Client.shared.send(request: request, to: chain) )

        let responseData = try await Client.shared.response(from: chain)?.data(using: .utf8)
        
        XCTAssertNotNil(responseData)

        let response = try JSONDecoder().decode(Response.self, from: responseData!)
        
        XCTAssertNotNil(request.identifier)
        
        XCTAssertEqual(response.identifier, request.identifier!)
        
        switch response.result {
        case .success(let json):
            XCTAssertEqual(json.description, "Polkadot")
        case .failure(_):
            XCTFail()
        }
    }
    
    func testJSONRPC2RequestInvalidJSON() async throws {
    
        XCTAssertThrowsError(try JSONRPC2Request(string: "invalid json") )
    }
    
    func testJSONRPC2RequestInvalidJSONRPCVersion() async throws {
    
        XCTAssertThrowsError(try JSONRPC2Request(string: "{\"id\":1,\"jsonrpc\":\"1.0\",\"method\":\"system_chain\",\"params\":[]}") )
    }
    
    func testJSONRPC2RequestChainNotAdded() async throws {
        let chain = Chain(specification: .kusama)
        
        let request = try JSONRPC2Request(string: "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_chain\",\"params\":[]}")
        
        XCTAssertThrowsError( try Client.shared.send(request: request, to: chain) )
    }

}


fileprivate extension Chain.Specification {
    
    static var polkadot: JSONObject {
        return jsonObject(resourceName: "polkadot")
    }
    
    static var kusama: JSONObject {
        return jsonObject(resourceName: "kusama")
    }
    
    private static func jsonObject(resourceName name: String) -> JSONObject {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            fatalError()
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError()
        }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? JSONObject else {
            fatalError()
        }
        return jsonObject
    }
}
