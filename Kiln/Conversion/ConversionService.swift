import Foundation

struct ConversionService: Sendable {
    var catalog: FormatCatalog
    var graph: ConversionGraph

    init(catalog: FormatCatalog = .shared) {
        self.catalog = catalog
        self.graph = ConversionGraph(catalog: catalog)
    }

    func identify(url: URL) -> Format? {
        catalog.format(for: url)
    }

    func destinations(for urls: [URL], mode: ConversionMode) -> [Format] {
        let formats = urls.compactMap { identify(url: $0) }
        return graph.commonDestinations(for: formats, mode: mode)
    }

    @discardableResult
    func convert(input: URL, to formatID: String, spec: OutputSpec) throws -> URL {
        guard let source = identify(url: input) else { throw KilnError.unsupported }
        guard let dest = catalog.format(id: formatID) else { throw KilnError.unsupported }
        guard graph.canRun(from: source, to: dest, mode: .convert) else { throw KilnError.unsupported }
        var job = spec
        job.mode = .convert
        job.formatID = formatID
        return try runConvert(input: input, source: source, dest: dest, spec: job)
    }

    @discardableResult
    func compress(input: URL, spec: OutputSpec) throws -> URL {
        guard let source = identify(url: input) else { throw KilnError.unsupported }
        let destID = spec.formatID ?? source.id
        guard let dest = catalog.format(id: destID) else { throw KilnError.unsupported }
        var job = spec
        job.mode = .compress
        switch source.family {
        case .image:
            return try ImageEngine.compress(input: input, format: dest, spec: job)
        case .pdf:
            return try PDFEngine.compress(input: input, spec: job)
        case .audio:
            return try AudioEngine.compress(input: input, format: dest, spec: job)
        case .video:
            return try VideoEngine.compress(input: input, format: dest, spec: job)
        case .data:
            return try DataEngine.compress(input: input, format: dest, spec: job)
        case .archive:
            return try ArchiveEngine.zip(inputs: [input], spec: job, stem: input)
        case .document:
            throw KilnError.unsupported
        }
    }

    @discardableResult
    func combine(inputs: [URL], spec: OutputSpec) throws -> URL {
        guard let first = inputs.first else { throw KilnError.unreadable }
        let destID = spec.formatID ?? "pdf"
        guard let dest = catalog.format(id: destID) else { throw KilnError.unsupported }
        if dest.id == "zip" {
            return try ArchiveEngine.zip(inputs: inputs, spec: spec, stem: first)
        }
        if dest.id == "pdf" {
            return try PDFEngine.imagesToPDF(inputs: inputs, spec: spec, stem: first)
        }
        throw KilnError.unsupported
    }

    @discardableResult
    func split(input: URL, spec: OutputSpec) throws -> [URL] {
        guard let source = identify(url: input) else { throw KilnError.unsupported }
        if source.family == .archive {
            return [try ArchiveEngine.unzip(input: input, spec: spec)]
        }
        guard source.id == "pdf" else { throw KilnError.unsupported }
        let destID = spec.formatID ?? "pdf"
        guard let dest = catalog.format(id: destID) else { throw KilnError.unsupported }
        return try PDFEngine.split(input: input, format: dest, spec: spec)
    }

    private func runConvert(input: URL, source: Format, dest: Format, spec: OutputSpec) throws -> URL {
        switch source.family {
        case .image:
            if dest.id == "pdf" {
                return try PDFEngine.imagesToPDF(inputs: [input], spec: spec, stem: input)
            }
            return try ImageEngine.convert(input: input, to: dest, spec: spec)
        case .pdf:
            if dest.id == "pdf" {
                return try PDFEngine.compress(input: input, spec: spec)
            }
            if dest.id == "txt" {
                return try PDFEngine.extractText(input: input, spec: spec)
            }
            if dest.family == .image {
                let urls = try PDFEngine.convertToImage(input: input, format: dest, spec: spec)
                guard let first = urls.first else { throw KilnError.unreadable }
                return first
            }
            throw KilnError.unsupported
        case .document:
            if ["txt", "rtf", "html", "markdown"].contains(source.id) {
                return try TextEngine.convert(input: input, to: dest, spec: spec)
            }
            return try OfficeEngine.convert(input: input, to: dest, spec: spec)
        case .data:
            return try DataEngine.convert(input: input, to: dest, spec: spec)
        case .audio:
            return try AudioEngine.convert(input: input, to: dest, spec: spec)
        case .video:
            return try VideoEngine.convert(input: input, to: dest, spec: spec)
        case .archive:
            if dest.id == "zip" {
                return try ArchiveEngine.zip(inputs: [input], spec: spec, stem: input)
            }
            throw KilnError.unsupported
        }
    }
}
