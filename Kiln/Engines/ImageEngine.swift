import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

enum ImageEngine {
    static func convert(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let out = OutputLocation.url(for: input, newExtension: format.preferredExtension, in: spec.destinationDirectory)
        try write(input: input, destination: out, uti: format.utType.identifier as CFString, spec: spec)
        return out
    }

    static func compress(input: URL, format: Format, spec: OutputSpec) throws -> URL {
        var next = spec
        if format.lossy {
            next.quality = min(spec.quality, 0.55)
        } else if spec.maxDimension == nil {
            next.maxDimension = 1600
        }
        return try convert(input: input, to: format, spec: next)
    }

    static func loadCGImage(from url: URL, maxDimension: Int?) throws -> CGImage {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            throw KilnError.unreadable
        }
        var options: [CFString: Any] = [kCGImageSourceShouldCacheImmediately: true]
        if let maxDimension {
            options[kCGImageSourceCreateThumbnailFromImageAlways] = true
            options[kCGImageSourceCreateThumbnailWithTransform] = true
            options[kCGImageSourceThumbnailMaxPixelSize] = maxDimension
            if let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                return thumb
            }
        }
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
            throw KilnError.unreadable
        }
        return resized(image, maxDimension: maxDimension)
    }

    static func write(input: URL, destination: URL, uti: CFString, spec: OutputSpec) throws {
        let image = try loadCGImage(from: input, maxDimension: spec.maxDimension)
        try write(image: image, from: input, destination: destination, uti: uti, spec: spec)
    }

    static func write(image: CGImage, from source: URL?, destination: URL, uti: CFString, spec: OutputSpec) throws {
        let prepared = spec.flattenSRGB ? flattenToSRGB(image) : image
        let count = (uti as String == "com.microsoft.ico" || uti as String == "com.apple.icns") ? 3 : 1
        guard let dest = CGImageDestinationCreateWithURL(destination as CFURL, uti, count, nil) else {
            throw KilnError.writeFailed
        }
        if count == 1 {
            CGImageDestinationAddImage(dest, prepared, properties(for: uti, spec: spec, source: source) as CFDictionary)
        } else {
            for size in [16, 32, 256] {
                let scaled = resized(prepared, maxDimension: size)
                CGImageDestinationAddImage(dest, scaled, properties(for: uti, spec: spec, source: nil) as CFDictionary)
            }
        }
        guard CGImageDestinationFinalize(dest) else {
            throw KilnError.conversionFailed("Image destination finalize failed")
        }
        guard FileManager.default.fileExists(atPath: destination.path) else {
            throw KilnError.writeFailed
        }
    }

    static func resized(_ image: CGImage, maxDimension: Int?) -> CGImage {
        guard let maxDimension else { return image }
        let longest = max(image.width, image.height)
        guard longest > maxDimension, longest > 0 else { return image }
        let scale = Double(maxDimension) / Double(longest)
        let width = max(1, Int((Double(image.width) * scale).rounded()))
        let height = max(1, Int((Double(image.height) * scale).rounded()))
        let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace.model == .rgb ? colorSpace : CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else { return image }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage() ?? image
    }

    private static func flattenToSRGB(_ image: CGImage) -> CGImage {
        let space = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: bitmapInfo
        ) else { return image }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return ctx.makeImage() ?? image
    }

    private static func properties(for uti: CFString, spec: OutputSpec, source: URL?) -> [CFString: Any] {
        var props: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: spec.quality
        ]
        if !spec.stripMetadata, let source,
           let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil),
           let original = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] {
            if spec.stripMetadata == false {
                props.merge(original) { current, _ in current }
            }
        }
        return props
    }
}
