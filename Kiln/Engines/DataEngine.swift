import Foundation

enum DataEngine {
    static func convert(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let object = try load(from: input)
        let out = OutputLocation.url(for: input, newExtension: format.preferredExtension, in: spec.destinationDirectory)
        switch format.id {
        case "json":
            let pretty = spec.quality > 0.7
            var options: JSONSerialization.WritingOptions = pretty ? [.prettyPrinted, .sortedKeys] : []
            options.insert(.fragmentsAllowed)
            let data = try JSONSerialization.data(withJSONObject: object, options: options)
            try data.write(to: out)
        case "plist":
            let data = try PropertyListSerialization.data(fromPropertyList: object, format: .xml, options: 0)
            try data.write(to: out)
        case "xml":
            let data = try xmlData(from: object)
            try data.write(to: out)
        case "yaml":
            try emitYAML(object).write(to: out, atomically: true, encoding: .utf8)
        case "csv", "tsv":
            let sep = format.id == "tsv" ? "\t" : ","
            try table(from: object, separator: sep).write(to: out, atomically: true, encoding: .utf8)
        default:
            throw KilnError.unsupported
        }
        return out
    }

    static func compress(input: URL, format: Format, spec: OutputSpec) throws -> URL {
        var next = spec
        next.quality = 0.1
        return try convert(input: input, to: format, spec: next)
    }

    private static func load(from url: URL) throws -> Any {
        let ext = url.pathExtension.lowercased()
        let data = try Data(contentsOf: url)
        switch ext {
        case "json":
            return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        case "plist":
            return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        case "xml":
            return try JSONSerialization.jsonObject(with: try xmlToJSON(data), options: [.fragmentsAllowed])
        case "yaml", "yml":
            return try parseYAML(String(data: data, encoding: .utf8) ?? "")
        case "csv":
            return parseTable(String(data: data, encoding: .utf8) ?? "", separator: ",")
        case "tsv":
            return parseTable(String(data: data, encoding: .utf8) ?? "", separator: "\t")
        default:
            throw KilnError.unsupported
        }
    }

    private static func parseTable(_ text: String, separator: Character) -> [[String]] {
        text.split(whereSeparator: \.isNewline).map { line in
            splitCSV(String(line), separator: separator)
        }
    }

    private static func splitCSV(_ line: String, separator: Character) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var chars = Array(line)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == "\"" {
                if inQuotes, i + 1 < chars.count, chars[i + 1] == "\"" {
                    current.append("\"")
                    i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if c == separator, !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(c)
            }
            i += 1
        }
        result.append(current)
        return result
    }

    private static func table(from object: Any, separator: String) -> String {
        if let rows = object as? [[String]] {
            return rows.map { $0.map { escape($0, separator: separator) }.joined(separator: separator) }.joined(separator: "\n") + "\n"
        }
        if let dict = object as? [String: Any] {
            let keys = dict.keys.sorted()
            let header = keys.joined(separator: separator)
            let row = keys.map { escape(stringify(dict[$0]!), separator: separator) }.joined(separator: separator)
            return header + "\n" + row + "\n"
        }
        if let array = object as? [Any] {
            return array.map { stringify($0) }.joined(separator: "\n") + "\n"
        }
        return stringify(object) + "\n"
    }

    private static func escape(_ value: String, separator: String) -> String {
        if value.contains(separator) || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func stringify(_ value: Any) -> String {
        if let s = value as? String { return s }
        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value),
           let s = String(data: data, encoding: .utf8) {
            return s
        }
        return String(describing: value)
    }

    private static func emitYAML(_ object: Any, indent: Int = 0) -> String {
        let pad = String(repeating: "  ", count: indent)
        if let dict = object as? [String: Any] {
            if dict.isEmpty { return pad + "{}\n" }
            return dict.keys.sorted().map { key in
                let value = dict[key]!
                if value is [String: Any] || value is [Any] {
                    return "\(pad)\(key):\n\(emitYAML(value, indent: indent + 1))"
                }
                return "\(pad)\(key): \(yamlScalar(value))\n"
            }.joined()
        }
        if let array = object as? [Any] {
            if array.isEmpty { return pad + "[]\n" }
            return array.map { item in
                if item is [String: Any] || item is [Any] {
                    return "\(pad)-\n\(emitYAML(item, indent: indent + 1))"
                }
                return "\(pad)- \(yamlScalar(item))\n"
            }.joined()
        }
        return pad + yamlScalar(object) + "\n"
    }

    private static func yamlScalar(_ value: Any) -> String {
        if let s = value as? String {
            if s.contains(":") || s.contains("#") || s.contains("\n") || s.isEmpty {
                return "\"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
            }
            return s
        }
        if value is NSNull { return "null" }
        if let n = value as? NSNumber {
            let objcType = String(cString: n.objCType)
            if objcType == "c" || objcType == "B" { return n.boolValue ? "true" : "false" }
        }
        return String(describing: value)
    }

    private static func parseYAML(_ text: String) throws -> Any {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            if let data = trimmed.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
                return obj
            }
        }
        var dict: [String: Any] = [:]
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            if line.hasPrefix("- ") {
                // Simple list fallback stored as array of strings
                continue
            }
            if let idx = line.firstIndex(of: ":") {
                let key = String(line[..<idx]).trimmingCharacters(in: .whitespaces)
                var value = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
                if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
                    value = String(value.dropFirst().dropLast())
                }
                dict[key] = value
            }
        }
        if dict.isEmpty { throw KilnError.conversionFailed("Could not parse YAML") }
        return dict
    }

    private static func xmlData(from object: Any) throws -> Data {
        let plist = try PropertyListSerialization.data(fromPropertyList: object, format: .xml, options: 0)
        return plist
    }

    private static func xmlToJSON(_ data: Data) throws -> Data {
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try JSONSerialization.data(withJSONObject: plist, options: [.fragmentsAllowed])
    }
}
