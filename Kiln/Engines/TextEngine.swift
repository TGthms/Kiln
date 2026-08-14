import Foundation
import AppKit
import UniformTypeIdentifiers

enum TextEngine {
    static func convert(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let source = try loadAttributed(from: input)
        switch format.id {
        case "txt":
            return try write(string: source.string, ext: "txt", from: input, spec: spec)
        case "markdown":
            return try write(string: source.string, ext: "md", from: input, spec: spec)
        case "html":
            let data = try source.data(
                from: NSRange(location: 0, length: source.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
            )
            let out = OutputLocation.url(for: input, newExtension: "html", in: spec.destinationDirectory)
            try data.write(to: out)
            return out
        case "rtf":
            let data = try source.data(
                from: NSRange(location: 0, length: source.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
            let out = OutputLocation.url(for: input, newExtension: "rtf", in: spec.destinationDirectory)
            try data.write(to: out)
            return out
        case "pdf":
            return try printToPDF(source, from: input, spec: spec)
        default:
            throw KilnError.unsupported
        }
    }

    static func loadAttributed(from url: URL) throws -> NSAttributedString {
        let ext = url.pathExtension.lowercased()
        if ext == "md" || ext == "markdown" {
            let raw = try String(contentsOf: url, encoding: .utf8)
            return NSAttributedString(string: markdownToPlain(raw))
        }
        if ext == "txt" || ext == "text" {
            let raw = try String(contentsOf: url, encoding: .utf8)
            return NSAttributedString(string: raw)
        }
        do {
            return try NSAttributedString(
                url: url,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            )
        } catch {
            let raw = try String(contentsOf: url, encoding: .utf8)
            return NSAttributedString(string: raw)
        }
    }

    static func markdownToPlain(_ markdown: String) -> String {
        var lines: [String] = []
        for line in markdown.components(separatedBy: .newlines) {
            var next = line
            if next.hasPrefix("### ") { next = String(next.dropFirst(4)) }
            else if next.hasPrefix("## ") { next = String(next.dropFirst(3)) }
            else if next.hasPrefix("# ") { next = String(next.dropFirst(2)) }
            next = next.replacingOccurrences(of: "**", with: "")
            next = next.replacingOccurrences(of: "__", with: "")
            next = next.replacingOccurrences(of: "`", with: "")
            if next.hasPrefix("- ") { next = "• " + String(next.dropFirst(2)) }
            lines.append(next)
        }
        return lines.joined(separator: "\n")
    }

    static func markdownToHTML(_ markdown: String) -> String {
        let escaped = markdown
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        var html = "<html><head><meta charset=\"utf-8\"></head><body>\n"
        for line in escaped.components(separatedBy: .newlines) {
            if line.hasPrefix("### ") { html += "<h3>\(line.dropFirst(4))</h3>\n" }
            else if line.hasPrefix("## ") { html += "<h2>\(line.dropFirst(3))</h2>\n" }
            else if line.hasPrefix("# ") { html += "<h1>\(line.dropFirst(2))</h1>\n" }
            else if line.hasPrefix("- ") { html += "<li>\(line.dropFirst(2))</li>\n" }
            else if line.isEmpty { html += "<p></p>\n" }
            else { html += "<p>\(line)</p>\n" }
        }
        html += "</body></html>\n"
        return html
    }

    private static func write(string: String, ext: String, from input: URL, spec: OutputSpec) throws -> URL {
        let out = OutputLocation.url(for: input, newExtension: ext, in: spec.destinationDirectory)
        try string.write(to: out, atomically: true, encoding: .utf8)
        return out
    }

    private static func printToPDF(_ text: NSAttributedString, from input: URL, spec: OutputSpec) throws -> URL {
        let out = OutputLocation.url(for: input, newExtension: "pdf", in: spec.destinationDirectory)
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            throw KilnError.writeFailed
        }
        let inset = CGRect(x: 56, y: 56, width: 500, height: 680)
        var range = CFRange(location: 0, length: text.length)
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        while range.location < text.length {
            ctx.beginPDFPage(nil)
            let path = CGMutablePath()
            path.addRect(inset)
            let frame = CTFramesetterCreateFrame(framesetter, range, path, nil)
            CTFrameDraw(frame, ctx)
            let visible = CTFrameGetVisibleStringRange(frame)
            range.location += visible.length
            range.length = text.length - range.location
            ctx.endPDFPage()
            if visible.length == 0 { break }
        }
        ctx.closePDF()
        try (data as Data).write(to: out)
        return out
    }
}
