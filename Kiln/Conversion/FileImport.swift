import Foundation
import UniformTypeIdentifiers

enum FileImport {
    static func identityKey(for url: URL) -> String {
        url.standardizedFileURL.path
    }

    static func uniqueNew(urls: [URL], already: [URL]) -> [URL] {
        collectFiles(from: urls, already: already)
    }

    /// Iterative flatten. Never recurses, so a deep or cyclic folder cannot blow the stack.
    static func collectFiles(
        from urls: [URL],
        already: [URL],
        maxDepth: Int = 6,
        maxCount: Int = 400
    ) -> [URL] {
        var seen = Set(already.map(identityKey(for:)))
        var result: [URL] = []
        var stack: [(URL, Int)] = urls.reversed().map { ($0, 0) }
        let fm = FileManager.default
        while let (url, depth) = stack.popLast() {
            if result.count >= maxCount { break }
            let key = identityKey(for: url)
            if seen.contains(key) { continue }

            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: url.path, isDirectory: &isDir)
            if exists && isDir.boolValue {
                seen.insert(key)
                guard depth < maxDepth else { continue }
                let kids = (try? fm.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )) ?? []
                for kid in kids where kid.lastPathComponent != ".DS_Store" {
                    stack.append((kid, depth + 1))
                }
                continue
            }
            seen.insert(key)
            result.append(url.standardizedFileURL)
        }
        return result
    }

    /// Resolve an NSItemProvider / pasteboard payload to a file URL. Never throws.
    static func resolveProviderItem(_ item: Any?) -> URL? {
        if let url = item as? URL { return url }
        if let url = item as? NSURL { return url as URL }
        if let data = item as? Data {
            if let url = URL(dataRepresentation: data, relativeTo: nil) { return url }
            if let text = String(data: data, encoding: .utf8) {
                return urlFromText(text)
            }
        }
        if let text = item as? String { return urlFromText(text) }
        if let text = item as? NSString { return urlFromText(text as String) }
        return nil
    }

    static func prepare(
        urls: [URL],
        already: [URL],
        identify: (URL) -> Format?
    ) -> [(url: URL, format: Format?)] {
        collectFiles(from: urls, already: already).map { url in
            (url, identify(url))
        }
    }

    private static func urlFromText(_ text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("file:"), let url = URL(string: trimmed) { return url }
        if trimmed.hasPrefix("/") { return URL(fileURLWithPath: trimmed) }
        return nil
    }
}
