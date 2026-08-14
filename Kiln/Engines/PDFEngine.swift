import Foundation
import PDFKit
import ImageIO
import CoreGraphics

enum PDFEngine {
    static func imagesToPDF(inputs: [URL], spec: OutputSpec, stem: URL) throws -> URL {
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let out = OutputLocation.url(for: stem, newExtension: "pdf", in: spec.destinationDirectory)
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let ctx = CGContext(out as CFURL, mediaBox: &mediaBox, nil) else {
            throw KilnError.writeFailed
        }
        for input in inputs {
            let image: CGImage
            if isPDF(input) {
                image = try renderPDFPage(url: input, index: 0, spec: spec)
            } else {
                image = try ImageEngine.loadCGImage(from: input, maxDimension: spec.maxDimension)
            }
            var box = CGRect(x: 0, y: 0, width: image.width, height: image.height)
            if box.width < 1 || box.height < 1 {
                box = CGRect(x: 0, y: 0, width: 612, height: 792)
            }
            ctx.beginPDFPage([kCGPDFContextMediaBox as String: box] as CFDictionary)
            ctx.draw(image, in: box)
            ctx.endPDFPage()
        }
        ctx.closePDF()
        guard FileManager.default.fileExists(atPath: out.path) else { throw KilnError.writeFailed }
        return out
    }

    static func convertToImage(input: URL, format: Format, spec: OutputSpec) throws -> [URL] {
        guard let document = PDFDocument(url: input) else { throw KilnError.unreadable }
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let pageCount = document.pageCount
        guard pageCount > 0 else { throw KilnError.unreadable }
        let range = spec.pageRange.map { clamp($0, count: pageCount) } ?? 0...(pageCount - 1)
        var urls: [URL] = []
        for index in range {
            let image = try renderPDFPage(url: input, index: index, spec: spec)
            let suffix = pageCount == 1 ? nil : "-\(index + 1)"
            let out = OutputLocation.url(
                for: input,
                newExtension: format.preferredExtension,
                in: spec.destinationDirectory,
                preferring: suffix
            )
            try ImageEngine.write(
                image: image,
                from: nil,
                destination: out,
                uti: format.utType.identifier as CFString,
                spec: spec
            )
            urls.append(out)
        }
        return urls
    }

    static func extractText(input: URL, spec: OutputSpec) throws -> URL {
        guard let document = PDFDocument(url: input) else { throw KilnError.unreadable }
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let out = OutputLocation.url(for: input, newExtension: "txt", in: spec.destinationDirectory)
        let text = document.string ?? ""
        try text.write(to: out, atomically: true, encoding: .utf8)
        return out
    }

    static func split(input: URL, format: Format, spec: OutputSpec) throws -> [URL] {
        if format.id == "pdf" {
            return try splitToPDF(input: input, spec: spec)
        }
        return try convertToImage(input: input, format: format, spec: spec)
    }

    static func splitToPDF(input: URL, spec: OutputSpec) throws -> [URL] {
        guard let document = PDFDocument(url: input) else { throw KilnError.unreadable }
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        var urls: [URL] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let copy = PDFDocument()
            if let cloned = page.copy() as? PDFPage {
                copy.insert(cloned, at: 0)
            } else {
                copy.insert(page, at: 0)
            }
            let out = OutputLocation.url(
                for: input,
                newExtension: "pdf",
                in: spec.destinationDirectory,
                preferring: "-\(index + 1)"
            )
            guard copy.write(to: out) else { throw KilnError.writeFailed }
            urls.append(out)
        }
        if urls.isEmpty { throw KilnError.unreadable }
        return urls
    }

    static func compress(input: URL, spec: OutputSpec) throws -> URL {
        guard let document = PDFDocument(url: input) else { throw KilnError.unreadable }
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let out = OutputLocation.url(for: input, newExtension: "pdf", in: spec.destinationDirectory)
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let ctx = CGContext(out as CFURL, mediaBox: &mediaBox, nil) else {
            throw KilnError.writeFailed
        }
        let scale = max(0.35, spec.quality)
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            let pixelWidth = max(64, Int(bounds.width * 2 * scale))
            let image = render(page: page, width: pixelWidth)
            var box = bounds
            if box.width < 1 { box.size.width = 612 }
            if box.height < 1 { box.size.height = 792 }
            ctx.beginPDFPage([kCGPDFContextMediaBox as String: box] as CFDictionary)
            if let image {
                ctx.draw(image, in: box)
            }
            ctx.endPDFPage()
        }
        ctx.closePDF()
        guard FileManager.default.fileExists(atPath: out.path) else { throw KilnError.writeFailed }
        return out
    }

    static func renderPDFPage(url: URL, index: Int, spec: OutputSpec) throws -> CGImage {
        guard let document = PDFDocument(url: url), let page = document.page(at: index) else {
            throw KilnError.unreadable
        }
        let bounds = page.bounds(for: .mediaBox)
        var width = Int(max(bounds.width, 1) * 2)
        if let maxDimension = spec.maxDimension {
            let longest = max(bounds.width, bounds.height)
            if longest > 0 {
                width = Int((max(bounds.width, 1) * CGFloat(maxDimension)) / longest)
            }
        }
        guard let image = render(page: page, width: max(64, width)) else {
            throw KilnError.unreadable
        }
        return image
    }

    private static func render(page: PDFPage, width: Int) -> CGImage? {
        let bounds = page.bounds(for: .mediaBox)
        let scale = CGFloat(width) / max(bounds.width, 1)
        let height = max(1, Int(bounds.height * scale))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: max(1, width),
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.saveGState()
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: scale, y: -scale)
        page.draw(with: .mediaBox, to: ctx)
        ctx.restoreGState()
        return ctx.makeImage()
    }

    private static func isPDF(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "pdf"
    }

    private static func clamp(_ range: ClosedRange<Int>, count: Int) -> ClosedRange<Int> {
        let lower = min(max(range.lowerBound, 0), max(count - 1, 0))
        let upper = min(max(range.upperBound, lower), max(count - 1, 0))
        return lower...upper
    }
}
