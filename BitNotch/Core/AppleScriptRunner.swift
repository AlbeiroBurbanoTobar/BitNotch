import Foundation

struct AppleScriptError: Error, Sendable {
    /// `errAEEventNotPermitted`: the user denied BitNotch Automation access to the target app.
    static let notPermittedCode = -1743

    let code: Int
    let message: String

    var isNotPermitted: Bool { code == Self.notPermittedCode }
}

/// Runs AppleScript off the main thread, so a slow app or a permission prompt never blocks the UI.
/// `NSAppleScript` is not thread-safe, so every script runs on one serial queue.
final class AppleScriptRunner: @unchecked Sendable {
    static let shared = AppleScriptRunner()

    private let queue = DispatchQueue(label: "com.bitnotch.applescript")
    /// Compiled scripts keyed by source. Only accessed on `queue`.
    private var compiledScripts: [String: NSAppleScript] = [:]

    /// Runs `source` and converts its result with `parse`, which runs on the script queue.
    /// Pass `cache: false` for one-off sources (for example ones with an interpolated value).
    func run<Value: Sendable>(
        _ source: String,
        cache: Bool = true,
        parse: @escaping @Sendable (NSAppleEventDescriptor) -> Value
    ) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let result = Result { try self.execute(source, cache: cache) }.map(parse)
                continuation.resume(with: result)
            }
        }
    }

    func run(_ source: String, cache: Bool = true) async throws {
        try await run(source, cache: cache) { _ in () }
    }

    private func execute(_ source: String, cache: Bool) throws -> NSAppleEventDescriptor {
        guard let script = compiledScripts[source] ?? NSAppleScript(source: source) else {
            throw AppleScriptError(code: -1, message: "Could not create the script.")
        }
        if cache {
            compiledScripts[source] = script
        }

        var errorInfo: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw AppleScriptError(
                code: errorInfo[NSAppleScript.errorNumber] as? Int ?? -1,
                message: errorInfo[NSAppleScript.errorMessage] as? String ?? "The script failed."
            )
        }
        return descriptor
    }
}

extension NSAppleEventDescriptor {
    /// Items of an AppleScript list. Descriptor indices are 1-based.
    var listItems: [NSAppleEventDescriptor] {
        guard numberOfItems > 0 else { return [] }
        return (1...numberOfItems).compactMap { atIndex($0) }
    }
}
