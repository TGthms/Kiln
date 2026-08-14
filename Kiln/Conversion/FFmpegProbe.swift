import Foundation

enum FFmpegProbe: Sendable {
    static let defaultPaths = [
        "/opt/homebrew/bin/ffmpeg",
        "/usr/local/bin/ffmpeg",
    ]

    static var resolvedPath: String? {
        for path in defaultPaths where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }

    static var isAvailable: Bool { resolvedPath != nil }
}
