import Foundation
import Hummingbird
import HummingbirdXCT
import XCTest

class HummingbirdDateTests: XCTestCase {
    func testRFC1123Renderer() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, d MMM yyy HH:mm:ss z"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for _ in 0..<1000 {
            let time = Int.random(in: 1...4 * Int(Int32.max))
            XCTAssertEqual(formatter.string(from: Date(timeIntervalSince1970: Double(time))), HBDateCache.formatRFC1123Date(time))
        }
    }

    func testDateHeader() {
        let app = HBApplication(testing: .embedded)
        app.router.get("date") { _ in
            return "hello"
        }

        app.XCTStart()
        defer { app.XCTStop() }

        app.XCTExecute(uri: "/date", method: .GET) { response in
            XCTAssertNotNil(response.headers["date"].first)
        }
        app.XCTExecute(uri: "/date", method: .GET) { response in
            XCTAssertNotNil(response.headers["date"].first)
        }
    }
}
