import Hummingbird

/// Response structure returned by XCT testing framework
public struct HBXCTResponse {
    /// response status
    public let status: HTTPResponseStatus
    /// response headers
    public let headers: HTTPHeaders
    /// response body
    public let body: ByteBuffer?
}

/// Errors thrown by XCT framework.
enum HBXCTError: Error {
    case noHead
    case illegalBody
    case noEnd
}

/// Protocol for XCT framework.
public protocol HBXCT {
    /// Called to start testing of application
    func start(application: HBApplication)
    /// Called to stop testing of application
    func stop(application: HBApplication)
    /// Execute URL request and provide response
    func execute(
        uri: String,
        method: HTTPMethod,
        headers: HTTPHeaders,
        body: ByteBuffer?
    ) -> EventLoopFuture<HBXCTResponse>
    /// EventLoopGroup used by XCT framework
    var eventLoopGroup: EventLoopGroup { get }
}
