import Foundation
import ImageIO
import UniformTypeIdentifiers

final class FormatCatalog: @unchecked Sendable {
    static let shared = FormatCatalog()

    private(set) var formats: [Format]
    private var byID: [String: Format]
    private var byExtension: [String: Format]
    private var byUTI: [String: Format]

    private init() {
        var list: [Format] = FormatCatalog.seed
        FormatCatalog.mergeImageIO(&list)
        if FFmpegProbe.isAvailable {
            list.append(contentsOf: FormatCatalog.ffmpegFormats)
        }
        self.formats = list
        self.byID = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        var extMap: [String: Format] = [:]
        var utiMap: [String: Format] = [:]
        for format in list {
            for ext in format.extensions {
                extMap[ext.lowercased()] = format
            }
            utiMap[format.utType.identifier.lowercased()] = format
        }
        self.byExtension = extMap
        self.byUTI = utiMap
    }

    func format(id: String) -> Format? { byID[id] }

    func format(for url: URL) -> Format? {
        let ext = url.pathExtension.lowercased()
        if !ext.isEmpty, let format = byExtension[ext] {
            return format
        }
        if let values = try? url.resourceValues(forKeys: [.contentTypeKey]),
           let type = values.contentType {
            if let exact = byUTI[type.identifier.lowercased()] {
                return exact
            }
            if let match = formats.first(where: { type.conforms(to: $0.utType) }) {
                return match
            }
        }
        if let type = UTType(filenameExtension: ext) {
            if let exact = byUTI[type.identifier.lowercased()] {
                return exact
            }
            return formats.first(where: { type.conforms(to: $0.utType) })
        }
        return nil
    }

    func writable(in family: FormatFamily) -> [Format] {
        formats.filter { $0.family == family && $0.canWrite }
    }

    static func imageDestinationIdentifiers() -> Set<String> {
        Set((CGImageDestinationCopyTypeIdentifiers() as? [String]) ?? [])
    }

    static func applyImageWriteCapabilities(_ list: inout [Format], destIDs: Set<String>) {
        for idx in list.indices where list[idx].family == .image {
            list[idx].canWrite = destIDs.contains(list[idx].utType.identifier)
        }
    }

    private static func make(
        _ id: String,
        _ name: String,
        _ uti: String,
        _ exts: [String],
        _ family: FormatFamily,
        read: Bool = true,
        write: Bool = false,
        ffmpeg: Bool = false,
        lossy: Bool = false
    ) -> Format {
        Format(
            id: id,
            displayName: name,
            utType: UTType(uti) ?? UTType(filenameExtension: exts[0]) ?? .data,
            extensions: exts,
            family: family,
            canRead: read,
            canWrite: write,
            requiresFFMPEG: ffmpeg,
            lossy: lossy
        )
    }

    private static let seed: [Format] = [
        // Image write flags are applied only from CGImageDestinationCopyTypeIdentifiers().
        make("jpeg", "JPEG", "public.jpeg", ["jpg", "jpeg", "jpe"], .image, lossy: true),
        make("png", "PNG", "public.png", ["png"], .image),
        make("heic", "HEIC", "public.heic", ["heic", "heif"], .image, lossy: true),
        make("tiff", "TIFF", "public.tiff", ["tif", "tiff"], .image),
        make("gif", "GIF", "com.compuserve.gif", ["gif"], .image),
        make("bmp", "BMP", "com.microsoft.bmp", ["bmp"], .image),
        make("webp", "WebP", "org.webmproject.webp", ["webp"], .image, lossy: true),
        make("avif", "AVIF", "public.avif", ["avif"], .image, lossy: true),
        make("jp2", "JPEG 2000", "public.jpeg-2000", ["jp2", "j2k"], .image, lossy: true),
        make("ico", "ICO", "com.microsoft.ico", ["ico"], .image),
        make("icns", "ICNS", "com.apple.icns", ["icns"], .image),
        make("tga", "TGA", "com.truevision.tga-image", ["tga"], .image),
        make("pbm", "PBM", "public.pbm", ["pbm", "pgm", "ppm"], .image),
        make("svg", "SVG", "public.svg-image", ["svg"], .image),
        make("psd", "PSD", "com.adobe.photoshop-image", ["psd"], .image),
        make("exr", "OpenEXR", "com.ilm.openexr-image", ["exr"], .image),
        make("hdr", "HDR", "public.radiance", ["hdr"], .image),
        make("dng", "DNG", "com.adobe.raw-image", ["dng"], .image),
        make("cr2", "CR2", "com.canon.cr2-raw-image", ["cr2", "cr3"], .image),
        make("nef", "NEF", "com.nikon.raw-image", ["nef"], .image),
        make("arw", "ARW", "com.sony.raw-image", ["arw"], .image),
        make("pdf", "PDF", "com.adobe.pdf", ["pdf"], .pdf, write: true),
        make("txt", "TXT", "public.plain-text", ["txt", "text"], .document, write: true),
        make("rtf", "RTF", "public.rtf", ["rtf"], .document, write: true),
        make("html", "HTML", "public.html", ["html", "htm"], .document, write: true),
        make("markdown", "Markdown", "net.daringfireball.markdown", ["md", "markdown"], .document, write: true),
        make("docx", "DOCX", "org.openxmlformats.wordprocessingml.document", ["docx", "doc"], .document),
        make("odt", "ODT", "org.oasis-open.opendocument.text", ["odt"], .document),
        make("xlsx", "XLSX", "org.openxmlformats.spreadsheetml.sheet", ["xlsx"], .document),
        make("pptx", "PPTX", "org.openxmlformats.presentationml.presentation", ["pptx"], .document),
        make("epub", "EPUB", "org.idpf.epub-container", ["epub"], .document),
        make("pages", "Pages", "com.apple.iwork.pages.sffpages", ["pages"], .document),
        make("json", "JSON", "public.json", ["json"], .data, write: true),
        make("yaml", "YAML", "public.yaml", ["yaml", "yml"], .data, write: true),
        make("xml", "XML", "public.xml", ["xml"], .data, write: true),
        make("plist", "Property List", "com.apple.property-list", ["plist"], .data, write: true),
        make("csv", "CSV", "public.comma-separated-values-text", ["csv"], .data, write: true),
        make("tsv", "TSV", "public.tab-separated-values-text", ["tsv"], .data, write: true),
        // WAV/AIFF/CAF are readable; AVAssetExportPresetAppleM4A cannot encode them.
        make("wav", "WAV", "com.microsoft.waveform-audio", ["wav"], .audio),
        make("aiff", "AIFF", "public.aiff-audio", ["aiff", "aif"], .audio),
        make("caf", "CAF", "com.apple.coreaudio-format", ["caf"], .audio),
        make("m4a", "M4A", "public.mpeg-4-audio", ["m4a", "aac"], .audio, write: true, lossy: true),
        make("mp3", "MP3", "public.mp3", ["mp3"], .audio, write: false, lossy: true),
        make("mp4", "MP4", "public.mpeg-4", ["mp4"], .video, write: true, lossy: true),
        make("mov", "MOV", "com.apple.quicktime-movie", ["mov"], .video, write: true, lossy: true),
        make("m4v", "M4V", "com.apple.m4v-video", ["m4v"], .video, write: true, lossy: true),
        make("zip", "ZIP", "public.zip-archive", ["zip"], .archive, write: true),
    ]

    private static let ffmpegFormats: [Format] = [
        make("mkv", "MKV", "org.matroska.mkv", ["mkv"], .video, write: true, ffmpeg: true, lossy: true),
        make("webm", "WebM", "org.webmproject.webm", ["webm"], .video, write: true, ffmpeg: true, lossy: true),
        make("avi", "AVI", "public.avi", ["avi"], .video, write: true, ffmpeg: true, lossy: true),
        make("flac", "FLAC", "org.xiph.flac", ["flac"], .audio, write: true, ffmpeg: true),
        make("ogg", "OGG", "org.xiph.ogg-audio", ["ogg", "oga"], .audio, write: true, ffmpeg: true, lossy: true),
        make("opus", "Opus", "org.xiph.opus", ["opus"], .audio, write: true, ffmpeg: true, lossy: true),
        make("mp3out", "MP3", "public.mp3", ["mp3"], .audio, write: true, ffmpeg: true, lossy: true),
    ]

    private static func mergeImageIO(_ list: inout [Format]) {
        let knownUTIs = Set(list.map(\.utType.identifier))
        let sourceIDs = (CGImageSourceCopyTypeIdentifiers() as? [String]) ?? []
        let destIDs = imageDestinationIdentifiers()
        for uti in sourceIDs where !knownUTIs.contains(uti) {
            guard let type = UTType(uti) else { continue }
            let ext = type.preferredFilenameExtension ?? type.identifier.split(separator: ".").last.map(String.init) ?? "img"
            let name = (type.localizedDescription ?? ext).uppercased()
            list.append(
                Format(
                    id: uti,
                    displayName: name,
                    utType: type,
                    extensions: [ext],
                    family: .image,
                    canRead: true,
                    canWrite: destIDs.contains(uti),
                    requiresFFMPEG: false,
                    lossy: destIDs.contains(uti) && (uti.contains("jpeg") || uti.contains("heic") || uti.contains("webp"))
                )
            )
        }
        applyImageWriteCapabilities(&list, destIDs: destIDs)
    }
}
