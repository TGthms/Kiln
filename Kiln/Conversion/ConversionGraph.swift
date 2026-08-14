import Foundation

struct ConversionEdge: Sendable, Hashable {
    var from: String
    var to: String
    var engine: String
}

struct ConversionGraph: Sendable {
    var catalog: FormatCatalog

    init(catalog: FormatCatalog = .shared) {
        self.catalog = catalog
    }

    func destinations(from format: Format, mode: ConversionMode) -> [Format] {
        switch mode {
        case .convert:
            return convertDestinations(from: format)
        case .compress:
            return compressDestinations(from: format)
        case .combine:
            return combineDestinations(from: format)
        case .split:
            return splitDestinations(from: format)
        }
    }

    func commonDestinations(for formats: [Format], mode: ConversionMode) -> [Format] {
        guard let first = formats.first else { return [] }
        var set = Set(destinations(from: first, mode: mode).map(\.id))
        for format in formats.dropFirst() {
            set.formIntersection(destinations(from: format, mode: mode).map(\.id))
        }
        let preferred = ["jpeg", "png", "heic", "webp", "pdf", "txt", "zip", "m4a", "mp4"]
        return set.compactMap { catalog.format(id: $0) }
            .sorted { a, b in
                let ia = preferred.firstIndex(of: a.id) ?? 100
                let ib = preferred.firstIndex(of: b.id) ?? 100
                if ia != ib { return ia < ib }
                return a.displayName < b.displayName
            }
    }

    func canRun(from: Format, to: Format, mode: ConversionMode) -> Bool {
        destinations(from: from, mode: mode).contains(to)
    }

    private func convertDestinations(from format: Format) -> [Format] {
        switch format.family {
        case .image:
            return catalog.formats.filter { dest in
                dest.canWrite && dest.id != format.id && (dest.family == .image || dest.id == "pdf")
            }
        case .pdf:
            return catalog.formats.filter { dest in
                dest.canWrite && (dest.family == .image || dest.id == "txt" || dest.id == "pdf")
            }
        case .document:
            return convertDocumentDestinations(from: format)
        case .data:
            return catalog.writable(in: .data).filter { $0.id != format.id }
        case .audio:
            return catalog.formats.filter { $0.canWrite && $0.family == .audio && $0.id != format.id }
        case .video:
            return catalog.formats.filter {
                $0.canWrite && ($0.family == .video || $0.family == .audio || $0.family == .image) && $0.id != format.id
            }
        case .archive:
            return catalog.formats.filter { $0.canWrite && $0.family == .archive }
        }
    }

    /// Destinations Office/Text engines can actually produce. Not "any writable document type".
    func convertTargetIDs(fromDocument format: Format) -> [String] {
        switch format.id {
        case "txt", "rtf", "html", "markdown":
            return ["txt", "rtf", "html", "markdown", "pdf"]
        case "docx", "odt":
            return ["txt", "rtf", "html", "markdown", "pdf"]
        case "xlsx":
            return ["csv", "json", "tsv", "txt"]
        case "pptx", "epub":
            return ["txt", "markdown", "html", "pdf"]
        case "pages":
            return ["pdf", "txt", "png", "jpeg"]
        default:
            return []
        }
    }

    private func convertDocumentDestinations(from format: Format) -> [Format] {
        convertTargetIDs(fromDocument: format)
            .compactMap { catalog.format(id: $0) }
            .filter { $0.id != format.id && $0.canWrite }
    }

    private func compressDestinations(from format: Format) -> [Format] {
        switch format.family {
        case .image:
            // Stay in-format when the encoder can write; otherwise fall back to JPEG.
            if format.canWrite { return [format] }
            return catalog.format(id: "jpeg").map { [$0] } ?? []
        case .pdf:
            return catalog.format(id: "pdf").map { [$0] } ?? []
        case .audio, .video:
            if format.canWrite { return [format] }
            return catalog.formats.filter { $0.canWrite && $0.family == format.family }.prefix(1).map { $0 }
        case .archive:
            return catalog.format(id: "zip").map { [$0] } ?? []
        case .data:
            return format.canWrite ? [format] : []
        case .document:
            return []
        }
    }

    private func combineDestinations(from format: Format) -> [Format] {
        var result: [Format] = []
        if format.family == .image || format.id == "pdf" {
            if let pdf = catalog.format(id: "pdf") { result.append(pdf) }
        }
        if let zip = catalog.format(id: "zip") { result.append(zip) }
        return result
    }

    private func splitDestinations(from format: Format) -> [Format] {
        guard format.id == "pdf" || format.family == .archive else { return [] }
        if format.id == "pdf" {
            return catalog.formats.filter { $0.canWrite && ($0.family == .image || $0.id == "pdf") }
        }
        return []
    }
}
