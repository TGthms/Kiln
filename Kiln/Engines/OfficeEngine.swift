import Foundation

enum OfficeEngine {
    static func convert(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        let ext = input.pathExtension.lowercased()
        if ext == "xlsx" {
            return try convertXLSX(input: input, to: format, spec: spec)
        }
        if ext == "pptx" {
            return try convertPPTX(input: input, to: format, spec: spec)
        }
        if ext == "epub" {
            return try convertEPUB(input: input, to: format, spec: spec)
        }
        if ext == "pages" || ext == "numbers" || ext == "key" {
            return try convertIWork(input: input, to: format, spec: spec)
        }
        return try convertWithTextutil(input: input, to: format, spec: spec)
    }

    private static func convertWithTextutil(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        let textutil = "/usr/bin/textutil"
        guard FileManager.default.isExecutableFile(atPath: textutil) else {
            throw KilnError.conversionFailed("textutil is not available")
        }
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let intermediateExt: String
        switch format.id {
        case "txt": intermediateExt = "txt"
        case "rtf": intermediateExt = "rtf"
        case "html", "markdown", "pdf": intermediateExt = "html"
        default: throw KilnError.unsupported
        }
        let intermediate = OutputLocation.url(for: input, newExtension: intermediateExt, in: spec.destinationDirectory)
        try run(textutil, ["-convert", intermediateExt, "-output", intermediate.path, input.path])
        if format.id == "pdf" {
            let pdf = try TextEngine.convert(input: intermediate, to: format, spec: spec)
            try? FileManager.default.removeItem(at: intermediate)
            return pdf
        }
        if format.id == "markdown" {
            let html = try String(contentsOf: intermediate, encoding: .utf8)
            let out = OutputLocation.url(for: input, newExtension: "md", in: spec.destinationDirectory)
            try stripHTML(html).write(to: out, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(at: intermediate)
            return out
        }
        return intermediate
    }

    private static func convertXLSX(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        guard format.id == "csv" || format.id == "tsv" || format.id == "json" || format.id == "txt" else {
            throw KilnError.unsupported
        }
        let rows = try XLSXReader.rows(from: input)
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        switch format.id {
        case "json":
            let data = try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
            let out = OutputLocation.url(for: input, newExtension: "json", in: spec.destinationDirectory)
            try data.write(to: out)
            return out
        case "tsv":
            let text = rows.map { $0.joined(separator: "\t") }.joined(separator: "\n") + "\n"
            let out = OutputLocation.url(for: input, newExtension: "tsv", in: spec.destinationDirectory)
            try text.write(to: out, atomically: true, encoding: .utf8)
            return out
        default:
            let text = rows.map { $0.map(csvEscape).joined(separator: ",") }.joined(separator: "\n") + "\n"
            let out = OutputLocation.url(for: input, newExtension: "csv", in: spec.destinationDirectory)
            try text.write(to: out, atomically: true, encoding: .utf8)
            return out
        }
    }

    private static func convertPPTX(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        let text = try unzipGrep(input, prefix: "ppt/slides/")
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        if format.id == "txt" || format.id == "markdown" {
            let out = OutputLocation.url(for: input, newExtension: format.preferredExtension, in: spec.destinationDirectory)
            try text.write(to: out, atomically: true, encoding: .utf8)
            return out
        }
        if format.id == "html" || format.id == "pdf" {
            let htmlURL = OutputLocation.url(for: input, newExtension: "html", in: spec.destinationDirectory)
            let html = TextEngine.markdownToHTML(text)
            try html.write(to: htmlURL, atomically: true, encoding: .utf8)
            if format.id == "pdf" {
                let pdf = try TextEngine.convert(input: htmlURL, to: format, spec: spec)
                try? FileManager.default.removeItem(at: htmlURL)
                return pdf
            }
            return htmlURL
        }
        throw KilnError.unsupported
    }

    private static func convertEPUB(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        let text = try unzipGrep(input, prefix: "")
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        if format.id == "txt" || format.id == "markdown" {
            let out = OutputLocation.url(for: input, newExtension: format.preferredExtension, in: spec.destinationDirectory)
            try text.write(to: out, atomically: true, encoding: .utf8)
            return out
        }
        if format.id == "html" || format.id == "pdf" {
            let htmlURL = OutputLocation.url(for: input, newExtension: "html", in: spec.destinationDirectory)
            try TextEngine.markdownToHTML(text).write(to: htmlURL, atomically: true, encoding: .utf8)
            if format.id == "pdf" {
                let pdf = try TextEngine.convert(input: htmlURL, to: format, spec: spec)
                try? FileManager.default.removeItem(at: htmlURL)
                return pdf
            }
            return htmlURL
        }
        throw KilnError.unsupported
    }

    private static func convertIWork(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        // Many iWork packages contain a preview PDF.
        let preview = input.appendingPathComponent("preview.pdf")
        if FileManager.default.fileExists(atPath: preview.path) {
            if format.id == "pdf" {
                try OutputLocation.ensureDirectory(spec.destinationDirectory)
                let out = OutputLocation.url(for: input, newExtension: "pdf", in: spec.destinationDirectory)
                try FileManager.default.copyItem(at: preview, to: out)
                return out
            }
            if format.id == "txt" {
                return try PDFEngine.extractText(input: preview, spec: spec)
            }
            if format.family == .image {
                let urls = try PDFEngine.convertToImage(input: preview, format: format, spec: spec)
                guard let first = urls.first else { throw KilnError.unreadable }
                return first
            }
        }
        throw KilnError.unsupported
    }

    private static func unzipGrep(_ zip: URL, prefix: String) throws -> String {
        let unzip = "/usr/bin/unzip"
        guard FileManager.default.isExecutableFile(atPath: unzip) else {
            throw KilnError.conversionFailed("unzip is not available")
        }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        try run(unzip, ["-qq", "-o", zip.path, "-d", temp.path])
        var chunks: [String] = []
        if let enumerator = FileManager.default.enumerator(at: temp, includingPropertiesForKeys: nil) {
            for case let file as URL in enumerator {
                if !prefix.isEmpty && !file.path.contains(prefix) { continue }
                let ext = file.pathExtension.lowercased()
                if ext == "xml" || ext == "html" || ext == "xhtml" || ext == "txt" {
                    if let raw = try? String(contentsOf: file, encoding: .utf8) {
                        chunks.append(stripHTML(raw))
                    }
                }
            }
        }
        let text = chunks.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { throw KilnError.unreadable }
        return text
    }

    private static func stripHTML(_ raw: String) -> String {
        var s = raw
        s = s.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: "&nbsp;", with: " ")
        s = s.replacingOccurrences(of: "&amp;", with: "&")
        s = s.replacingOccurrences(of: "&lt;", with: "<")
        s = s.replacingOccurrences(of: "&gt;", with: ">")
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func run(_ launch: String, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launch)
        process.arguments = arguments
        let err = Pipe()
        process.standardError = err
        process.standardOutput = Pipe()
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let message = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw KilnError.conversionFailed(message)
        }
    }
}

enum XLSXReader {
    static func rows(from url: URL) throws -> [[String]] {
        let unzip = "/usr/bin/unzip"
        guard FileManager.default.isExecutableFile(atPath: unzip) else {
            throw KilnError.conversionFailed("unzip is not available")
        }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unzip)
        process.arguments = ["-qq", "-o", url.path, "-d", temp.path]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 { throw KilnError.unreadable }
        let strings = sharedStrings(in: temp)
        let sheet = temp.appendingPathComponent("xl/worksheets/sheet1.xml")
        guard let xml = try? String(contentsOf: sheet, encoding: .utf8) else { throw KilnError.unreadable }
        return parseSheet(xml, strings: strings)
    }

    private static func sharedStrings(in root: URL) -> [String] {
        let url = root.appendingPathComponent("xl/sharedStrings.xml")
        guard let xml = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var result: [String] = []
        let regex = try? NSRegularExpression(pattern: "<si>(.*?)</si>", options: [.dotMatchesLineSeparators])
        let ns = xml as NSString
        let matches = regex?.matches(in: xml, range: NSRange(location: 0, length: ns.length)) ?? []
        let tRegex = try? NSRegularExpression(pattern: "<t[^>]*>(.*?)</t>", options: [.dotMatchesLineSeparators])
        for match in matches {
            let chunk = ns.substring(with: match.range(at: 1))
            let tMatches = tRegex?.matches(in: chunk, range: NSRange(location: 0, length: (chunk as NSString).length)) ?? []
            let text = tMatches.map { (chunk as NSString).substring(with: $0.range(at: 1)) }.joined()
            result.append(text)
        }
        return result
    }

    private static func parseSheet(_ xml: String, strings: [String]) -> [[String]] {
        var rows: [[String]] = []
        let rowRegex = try? NSRegularExpression(pattern: "<row[^>]*>(.*?)</row>", options: [.dotMatchesLineSeparators])
        let cellRegex = try? NSRegularExpression(pattern: "<c([^>]*)>(.*?)</c>", options: [.dotMatchesLineSeparators])
        let vRegex = try? NSRegularExpression(pattern: "<v>(.*?)</v>", options: [])
        let ns = xml as NSString
        let rowMatches = rowRegex?.matches(in: xml, range: NSRange(location: 0, length: ns.length)) ?? []
        for rowMatch in rowMatches {
            let rowXML = ns.substring(with: rowMatch.range(at: 1))
            let rowNS = rowXML as NSString
            let cells = cellRegex?.matches(in: rowXML, range: NSRange(location: 0, length: rowNS.length)) ?? []
            var values: [String] = []
            for cell in cells {
                let attrs = rowNS.substring(with: cell.range(at: 1))
                let body = rowNS.substring(with: cell.range(at: 2))
                let v = vRegex?.firstMatch(in: body, range: NSRange(location: 0, length: (body as NSString).length))
                    .map { (body as NSString).substring(with: $0.range(at: 1)) } ?? ""
                if attrs.contains("t=\"s\""), let idx = Int(v), strings.indices.contains(idx) {
                    values.append(strings[idx])
                } else {
                    values.append(v)
                }
            }
            rows.append(values)
        }
        return rows
    }
}
