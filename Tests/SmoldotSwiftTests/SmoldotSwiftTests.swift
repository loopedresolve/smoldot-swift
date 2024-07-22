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
        
        XCTAssertFalse( chain.isValid )
    }
    
    func testAddChain() throws {
        /// Add the chain to the client
        XCTAssertNoThrow( try Client.shared.add(chain: &chain) )
        
        XCTAssertTrue( chain.isValid )
    }
    
    func testAddChainAlreadyAdded() throws {
        /// Add the chain to the client
        XCTAssertNoThrow( try Client.shared.add(chain: &chain) )

        /// Add the chain to the client again
        XCTAssertThrowsError( try Client.shared.add(chain: &chain) ) { error in
            XCTAssertTrue( error as! ClientError == ClientError.chainHasAlreadyBeenAdded )
        }
    }
    
    func testRemoveChain() throws {
        /// Add the chain to the client
        XCTAssertNoThrow( try Client.shared.add(chain: &chain) )
        XCTAssertTrue( chain.isValid )
        
        /// Remove the chain from the client
        XCTAssertNoThrow( try Client.shared.remove(chain: &chain) )
        XCTAssertFalse( chain.isValid )
    }
    
    func testRemoveChainNotAdded() throws {
        /// Try to remove the chain when it has not been added to the client.
        XCTAssertThrowsError( try Client.shared.remove(chain: &chain) ) { error in
            XCTAssertTrue( error as! ClientError == ClientError.chainNotFound )
        }
    }
    
    func testJSONRPC2RequestInvalidJSON() async throws {
        /// Try to build a JSON-RPC2 request from a non-JSON value.
        XCTAssertThrowsError( try JSONRPC2Request(string: "invalid json") ) { error in
            XCTAssertTrue( (error as! JSONRPC2Error).kind == JSONRPC2Error.invalidRequest )
        }
    }
    
    func testJSONRPC2RequestInvalidJSONRPCVersion() async throws {
        /// Try to build a JSON-RPC 1.0 request.
        XCTAssertThrowsError( try JSONRPC2Request(string: "{\"id\":1,\"jsonrpc\":\"1.0\",\"method\":\"system_chain\",\"params\":[]}") ) { error in
            XCTAssertTrue( (error as! JSONRPC2Error).kind == JSONRPC2Error.invalidRequest )
        }
    }
    
    func testJSONRPC2RequestChainNotAdded() async throws {
        /// Try to send a request to a chain without first adding it to the client.
        let request = try? JSONRPC2Request(string: "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"system_chain\",\"params\":[]}")
        XCTAssertNotNil(request)
        
        XCTAssertThrowsError( try Client.shared.send(request: request!, to: chain) ) { error in
            XCTAssertTrue( error as! ClientError == ClientError.chainNotFound )
        }
    }

}
