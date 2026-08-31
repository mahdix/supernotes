import OSLog

nonisolated enum Log {
    static let app = Logger(subsystem: "io.github.mahdix.supernotes", category: "app")
    static let storage = Logger(subsystem: "io.github.mahdix.supernotes", category: "storage")
    static let window = Logger(subsystem: "io.github.mahdix.supernotes", category: "window")
    static let shortcuts = Logger(subsystem: "io.github.mahdix.supernotes", category: "shortcuts")
    static let navigation = Logger(subsystem: "io.github.mahdix.supernotes", category: "navigation")
    static let updates = Logger(subsystem: "io.github.mahdix.supernotes", category: "updates")
    static let peek = Logger(subsystem: "io.github.mahdix.supernotes", category: "peek")
}
