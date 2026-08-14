import Foundation

enum ArchiveEngine {
    static func zip(inputs: [URL], spec: OutputSpec, stem: URL) throws -> URL {
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let out = OutputLocation.url(for: stem, newExtension: "zip", in: spec.destinationDirectory)
        let zip = "/usr/bin/zip"
        guard FileManager.default.isExecutableFile(atPath: zip) else {
            throw KilnError.conversionFailed("zip is not available")
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: zip)
        var args = ["-j", "-q"]
        if spec.quality < 0.4 {
            args.append("-9")
        } else if spec.quality > 0.85 {
            args.append("-1")
        }
        args.append(out.path)
        args.append(contentsOf: inputs.map(\.path))
        process.arguments = args
        process.currentDirectoryURL = spec.destinationDirectory
        let err = Pipe()
        process.standardError = err
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 || !FileManager.default.fileExists(atPath: out.path) {
            throw KilnError.conversionFailed("zip failed")
        }
        return out
    }

    static func unzip(input: URL, spec: OutputSpec) throws -> URL {
        let unzip = "/usr/bin/unzip"
        guard FileManager.default.isExecutableFile(atPath: unzip) else {
            throw KilnError.conversionFailed("unzip is not available")
        }
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let folder = OutputLocation.url(for: input, newExtension: "unpacked", in: spec.destinationDirectory)
            .deletingPathExtension()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unzip)
        process.arguments = ["-qq", "-o", input.path, "-d", folder.path]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw KilnError.conversionFailed("unzip failed")
        }
        return folder
    }
}
