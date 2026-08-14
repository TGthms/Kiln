import AppKit
import ImageIO
import PDFKit

/// Previews for the queue. Runs anywhere — never QuickLook, whose callback
/// is not on the main actor and crashed the @MainActor AppModel in Swift 6.
enum ThumbnailLoader {
    static func make(at url: URL, maxPixel: CGFloat = 240) -> NSImage? {
        if url.pathExtension.lowercased() == "pdf" {
            return pdfThumbnail(at: url, maxPixel: maxPixel)
        }
        if let image = imageIOThumbnail(at: url, maxPixel: maxPixel) {
            return image
        }
        return pdfThumbnail(at: url, maxPixel: maxPixel)
    }

    private static func imageIOThumbnail(at url: URL, maxPixel: CGFloat) -> NSImage? {
        let srcOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, srcOptions) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }

    private static func pdfThumbnail(at url: URL, maxPixel: CGFloat) -> NSImage? {
        guard let document = PDFDocument(url: url), let page = document.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = min(maxPixel / bounds.width, maxPixel / bounds.height, 1)
        let size = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        let image = page.thumbnail(of: size, for: .mediaBox)
        withExtendedLifetime(document) {}
        return image
    }
}
