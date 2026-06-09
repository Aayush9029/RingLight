import os

@main
struct RingLight {
    private static let logger = Logger(
        subsystem: "com.aayush.opensource.RingLight",
        category: "CommandLine"
    )

    static func main() {
        logger.info("RingLight command line target launched")
    }
}
