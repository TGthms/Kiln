import Foundation

enum FFmpegEngine {
    static func convert(input: URL, output: URL, format: Format, spec: OutputSpec) throws -> URL {
        guard let bin = FFmpegProbe.resolvedPath else { throw KilnError.unsupported }
        var args = ["-y", "-i", input.path]
        if format.family == .audio {
            if spec.quality < 0.5 {
                args += ["-b:a", "96k"]
            }
        } else if format.family == .video {
            if spec.quality < 0.45 {
                args += ["-vf", "scale='min(1280,iw)':-2", "-b:v", "800k"]
            } else if let maxDimension = spec.maxDimension {
                args += ["-vf", "scale='min(\(maxDimension),iw)':-2"]
            }
        }
        args.append(output.path)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: bin)
        process.arguments = args
        let err = Pipe()
        process.standardError = err
        process.standardOutput = Pipe()
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 || !FileManager.default.fileExists(atPath: output.path) {
            throw KilnError.conversionFailed("ffmpeg failed")
        }
        return output
    }
}
