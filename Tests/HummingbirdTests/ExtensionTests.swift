@testable import Hummingbird
import XCTest

extension HBApplication {
    class ActiveTest {
        var active: Bool
        init() {
            self.active = true
        }
    }

    var ext: Int? {
        get { return extensions.get(\.ext) }
        set { extensions.set(\.ext, value: newValue) }
    }

    var shutdownTest: ActiveTest? {
        get { return extensions.get(\.shutdownTest) }
        set {
            extensions.set(\.shutdownTest, value: newValue) { value in
                value?.active = false
            }
        }
    }
}

class ExtensionTests: XCTestCase {
    func testExtension() {
        let app = HBApplication()
        app.ext = 56
        XCTAssertEqual(app.ext, 56)
    }

    func testExtensionShutdown() throws {
        let app = HBApplication()
        let test = HBApplication.ActiveTest()
        app.shutdownTest = test
        try app.shutdownApplication()
        XCTAssertEqual(test.active, false)
    }

    func testEventLoopStorage() {
        var id = 0
        let app = HBApplication()
        app.eventLoopStorage.forEach { ev in
            ev.storage.id = id
            id += 1
        }

        var idMask: UInt64 = 0
        var iterator = app.eventLoopGroup.makeIterator()
        while let eventLoop = iterator.next() {
            let id = app.eventLoopStorage(for: eventLoop).id
            idMask |= 1 << id
        }
        XCTAssertEqual(1 << id, idMask + 1)
    }
}

extension HBApplication.EventLoopStorage {
    var id: Int {
        get { self.extensions.get(\.id) }
        set { self.extensions.set(\.id, value: newValue) }
    }
}
