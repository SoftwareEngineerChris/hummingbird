import Logging

/// Middleware outputting to log for every call to server
public struct HBLogRequestsMiddleware: HBMiddleware {
    let logLevel: Logger.Level
    let includeHeaders: Bool

    public init(_ logLevel: Logger.Level, includeHeaders: Bool = false) {
        self.logLevel = logLevel
        self.includeHeaders = includeHeaders
    }

    public func apply(to request: HBRequest, next: HBResponder) -> EventLoopFuture<HBResponse> {
        if self.includeHeaders {
            request.logger.log(
                level: self.logLevel,
                "\(request.headers)",
                metadata: ["hb_uri": .string(request.uri.description), "hb_method": .string(request.method.rawValue)]
            )
        } else {
            request.logger.log(
                level: self.logLevel,
                "",
                metadata: ["hb_uri": .string(request.uri.description), "hb_method": .string(request.method.rawValue)]
            )
        }
        return next.respond(to: request)
    }
}
