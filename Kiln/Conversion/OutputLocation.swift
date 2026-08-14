import Foundation

enum OutputLocation {
    static func url(
        for source: URL,
        newExtension: String,
        in directory: URL,
        preferring stemSuffix: String? = nil
    ) -> URL {
        let base = source.deletingPathExtension().lastPathComponent
        let stem = stemSuffix.map { "\(base)\($0)" } ?? base
        let ext = newExtension.hasPrefix(".") ? String(newExtension.dropFirst()) : newExtension
        var candidate = directory.appendingPathComponent("\(stem).\(ext)")
        if !FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        var n = 2
        while true {
            candidate = directory.appendingPathComponent("\(stem) \(n).\(ext)")
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            n += 1
        }
    }

    static func ensureDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
