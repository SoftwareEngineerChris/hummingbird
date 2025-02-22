import NIO

/// Current date cache.
///
/// Getting the current date formatted is an expensive operation. This creates a scheduled task that will
/// update a cached version of the date in the format as detailed in RFC1123 once every second. To
/// avoid threading issues it is assumed that `currentDate` will only every be accessed on the same
/// EventLoop that the update is running.
public class HBDateCache {
    /// Setup date caches (one for each eventLoop)
    static func initDateCaches(for eventLoopGroup: EventLoopGroup) {
        if let eventLoop = eventLoopGroup as? EmbeddedEventLoop {
            self.thread.currentValue = HBDateCache(eventLoop: eventLoop)
            return
        }
        let futures: [EventLoopFuture<Void>] = eventLoopGroup.map { thread.currentValue = HBDateCache(eventLoop: $0) }
        try! EventLoopFuture.andAllComplete(futures, on: eventLoopGroup.next()).wait()
    }

    /// Shutdown date caches (one for each eventLoop)
    static func shutdownDateCaches(for eventLoopGroup: EventLoopGroup) {
        if eventLoopGroup is EmbeddedEventLoop {
            self.thread.currentValue = nil
            return
        }
        let futures: [EventLoopFuture<Void>] = eventLoopGroup.flatMap { eventLoop -> EventLoopFuture<Void> in
            if let dateCache = thread.currentValue {
                return dateCache.shutdown(eventLoop: eventLoop)
            } else {
                return eventLoop.makeSucceededVoidFuture()
            }
        }
        try! EventLoopFuture.andAllComplete(futures, on: eventLoopGroup.next()).wait()
    }

    /// Current date string stored in DateCache
    public static var currentDate: String {
        return thread.currentValue!._currentDate
    }

    /// Initialize DateCache to run on a specific `EventLoop`
    private init(eventLoop: EventLoop) {
        assert(eventLoop.inEventLoop)
        var timeVal = timeval.init()
        gettimeofday(&timeVal, nil)
        self._currentDate = Self.formatRFC1123Date(timeVal.tv_sec)

        let millisecondsSinceLastSecond = Double(timeVal.tv_usec) / 1000.0
        let millisecondsUntilNextSecond = Int64(1000.0 - millisecondsSinceLastSecond)
        self.task = eventLoop.scheduleRepeatedTask(initialDelay: .milliseconds(millisecondsUntilNextSecond), delay: .seconds(1)) { _ in
            self.updateDate()
        }
    }

    private func shutdown(eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        self.task.cancel(promise: promise)
        return promise.futureResult.map { self.task = nil }
    }

    /// Render Epoch seconds as RFC1123 formatted date
    /// - Parameter epochTime: epoch seconds to render
    /// - Returns: Formatted date
    public static func formatRFC1123Date(_ epochTime: Int) -> String {
        var epochTime = epochTime
        var timeStruct = tm.init()
        gmtime_r(&epochTime, &timeStruct)
        let year = Int(timeStruct.tm_year + 1900)
        let day = self.dayNames[numericCast(timeStruct.tm_wday)]
        let month = self.monthNames[numericCast(timeStruct.tm_mon)]
        var formatted = day
        formatted.reserveCapacity(30)
        formatted += ", "
        formatted += timeStruct.tm_mday.description
        formatted += " "
        formatted += month
        formatted += " "
        formatted += self.numberNames[year / 100]
        formatted += self.numberNames[year % 100]
        formatted += " "
        formatted += self.numberNames[numericCast(timeStruct.tm_hour)]
        formatted += ":"
        formatted += self.numberNames[numericCast(timeStruct.tm_min)]
        formatted += ":"
        formatted += self.numberNames[numericCast(timeStruct.tm_sec)]
        formatted += " GMT"

        return formatted
    }

    private func updateDate() {
        let epochTime = time(nil)
        self._currentDate = Self.formatRFC1123Date(epochTime)
    }

    /// Thread-specific HBDateCache
    private static let thread: ThreadSpecificVariable<HBDateCache> = .init()

    /// Current formatted date
    private var _currentDate: String
    private var task: RepeatedTask!

    private static let dayNames = [
        "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat",
    ]

    private static let monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]

    private static let numberNames = [
        "00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
        "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
        "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
        "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
        "40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
        "50", "51", "52", "53", "54", "55", "56", "57", "58", "59",
        "60", "61", "62", "63", "64", "65", "66", "67", "68", "69",
        "70", "71", "72", "73", "74", "75", "76", "77", "78", "79",
        "80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
        "90", "91", "92", "93", "94", "95", "96", "97", "98", "99",
    ]
}
