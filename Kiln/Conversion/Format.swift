import Foundation
import UniformTypeIdentifiers

enum FormatFamily: String, Sendable, CaseIterable, Identifiable {
    case image
    case pdf
    case document
    case data
    case audio
    case video
    case archive

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .image: return "family.image"
        case .pdf: return "family.pdf"
        case .document: return "family.document"
        case .data: return "family.data"
        case .audio: return "family.audio"
        case .video: return "family.video"
        case .archive: return "family.archive"
        }
    }

    var kindKey: String {
        switch self {
        case .image: return "format.kind.image"
        case .pdf: return "format.kind.pdf"
        case .document: return "format.kind.document"
        case .data: return "format.kind.data"
        case .audio: return "format.kind.audio"
        case .video: return "format.kind.video"
        case .archive: return "format.kind.archive"
        }
    }
}

struct Format: Hashable, Sendable, Identifiable {
    var id: String
    var displayName: String
    var utType: UTType
    var extensions: [String]
    var family: FormatFamily
    var canRead: Bool
    var canWrite: Bool
    var requiresFFMPEG: Bool
    var lossy: Bool

    var preferredExtension: String { extensions.first ?? id }

    var typeIdentifier: String { utType.identifier }
}

enum WorkspaceMode: String, Sendable, CaseIterable, Identifiable {
    case files
    case units

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .files: return "workspace.files"
        case .units: return "workspace.units"
        }
    }
}

enum ConversionMode: String, Sendable, CaseIterable, Identifiable {
    case convert
    case compress
    case combine
    case split

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .convert: return "mode.convert"
        case .compress: return "mode.compress"
        case .combine: return "mode.combine"
        case .split: return "mode.split"
        }
    }

    var actionKey: String {
        switch self {
        case .convert: return "action.convert"
        case .compress: return "action.compress"
        case .combine: return "action.combine"
        case .split: return "action.split"
        }
    }
}

enum KilnPreset: String, Sendable, CaseIterable, Identifiable {
    case original
    case web
    case email
    case shareJPEG
    case lossless
    case smallest

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .original: return "preset.original"
        case .web: return "preset.web"
        case .email: return "preset.email"
        case .shareJPEG: return "preset.share_jpeg"
        case .lossless: return "preset.lossless"
        case .smallest: return "preset.smallest"
        }
    }

    var detailKey: String {
        switch self {
        case .original: return "preset.original.detail"
        case .web: return "preset.web.detail"
        case .email: return "preset.email.detail"
        case .shareJPEG: return "preset.share_jpeg.detail"
        case .lossless: return "preset.lossless.detail"
        case .smallest: return "preset.smallest.detail"
        }
    }

    var quality: Double {
        switch self {
        case .original: return 0.92
        case .web: return 0.82
        case .email: return 0.62
        case .shareJPEG: return 0.78
        case .lossless: return 1.0
        case .smallest: return 0.28
        }
    }

    var maxDimension: Int? {
        switch self {
        case .original, .lossless: return nil
        case .web: return 1920
        case .email: return 1600
        case .shareJPEG: return 2048
        case .smallest: return 1280
        }
    }

    var stripMetadata: Bool {
        switch self {
        case .original, .lossless: return false
        default: return true
        }
    }
}

enum DestinationPolicy: String, Sendable, CaseIterable, Identifiable {
    case sameFolder
    case downloads
    case choose

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .sameFolder: return "settings.destination.same"
        case .downloads: return "settings.destination.downloads"
        case .choose: return "settings.destination.choose"
        }
    }
}

struct OutputSpec: Sendable {
    var mode: ConversionMode
    var formatID: String?
    var quality: Double
    var maxDimension: Int?
    var stripMetadata: Bool
    var flattenSRGB: Bool
    var pageRange: ClosedRange<Int>?
    var destinationDirectory: URL

    init(
        mode: ConversionMode,
        formatID: String? = nil,
        quality: Double = 0.85,
        maxDimension: Int? = nil,
        stripMetadata: Bool = false,
        flattenSRGB: Bool = false,
        pageRange: ClosedRange<Int>? = nil,
        destinationDirectory: URL
    ) {
        self.mode = mode
        self.formatID = formatID
        self.quality = min(max(quality, 0.05), 1)
        self.maxDimension = maxDimension
        self.stripMetadata = stripMetadata
        self.flattenSRGB = flattenSRGB
        self.pageRange = pageRange
        self.destinationDirectory = destinationDirectory
    }

    static func from(preset: KilnPreset, mode: ConversionMode, formatID: String?, directory: URL) -> OutputSpec {
        var format = formatID
        if preset == .shareJPEG, mode == .convert {
            format = "jpeg"
        }
        return OutputSpec(
            mode: mode,
            formatID: format,
            quality: preset.quality,
            maxDimension: preset.maxDimension,
            stripMetadata: preset.stripMetadata,
            destinationDirectory: directory
        )
    }
}

enum KilnError: Error, LocalizedError, Sendable {
    case unsupported
    case unreadable
    case writeFailed
    case conversionFailed(String)
    case missingDestination

    var errorDescription: String? {
        switch self {
        case .unsupported: return String(localized: "error.unsupported")
        case .unreadable: return String(localized: "error.conversion_failed")
        case .writeFailed: return String(localized: "error.write_permission")
        case .conversionFailed: return String(localized: "error.conversion_failed")
        case .missingDestination: return String(localized: "error.write_permission")
        }
    }
}
