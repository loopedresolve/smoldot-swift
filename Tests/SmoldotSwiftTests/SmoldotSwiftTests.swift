import XCTest
import JSON
import JSONRPC2
@testable import SmoldotSwift

final class SmoldotSwiftTests: XCTestCase {
    
    var chain: Chain!
    
    override func setUp() async throws {
        ///
        /// Chain specification file to use for testing. If adding a file, also explicitly declare the resource for
        /// the test target in the package manifest.
        ///
        let url = Bundle.module.url(forResource: "polkadot", withExtension: "json")!
        //let url = Bundle.module.url(forResource: "kusama", withExtension: "json")!
        //let url = Bundle.module.url(forResource: "rococo", withExtension: "json")!
        //let url = Bundle.module.url(forResource: "westend", withExtension: "json")!
        
        chain = try Chain(specificationFile: url)
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
        // TODO: revisit
        
        /*
        let chain = Chain(specification: .kusama)
        
        let request = try JSONRPC2Request(string: "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_chain\",\"params\":[]}")
        
        XCTAssertThrowsError( try Client.shared.send(request: request, to: chain) )
         */
    }

}
