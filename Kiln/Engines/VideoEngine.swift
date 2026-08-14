import Foundation
import AVFoundation

enum VideoEngine {
    static func convert(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        if format.family == .audio {
            return try AudioEngine.convert(input: input, to: format, spec: spec)
        }
        if format.family == .image {
            return try posterFrame(input: input, format: format, spec: spec)
        }
        let out = OutputLocation.url(for: input, newExtension: format.preferredExtension, in: spec.destinationDirectory)
        if format.requiresFFMPEG {
            return try FFmpegEngine.convert(input: input, output: out, format: format, spec: spec)
        }
        try export(input: input, output: out, format: format, spec: spec)
        return out
    }

    static func compress(input: URL, format: Format, spec: OutputSpec) throws -> URL {
        var next = spec
        next.quality = min(spec.quality, 0.45)
        return try convert(input: input, to: format, spec: next)
    }

    private static func export(input: URL, output: URL, format: Format, spec: OutputSpec) throws {
        let asset = AVURLAsset(url: input)
        let preset: String
        if spec.quality < 0.45 {
            preset = AVAssetExportPresetMediumQuality
        } else if spec.quality < 0.75 {
            preset = AVAssetExportPreset1280x720
        } else {
            preset = AVAssetExportPresetHighestQuality
        }
        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw KilnError.conversionFailed("No video export session")
        }
        session.outputURL = output
        session.outputFileType = format.id == "mov" ? .mov : .mp4
        session.shouldOptimizeForNetworkUse = true
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var captured: Error?
        session.exportAsynchronously {
            captured = session.error
            semaphore.signal()
        }
        semaphore.wait()
        if let captured { throw captured }
        if session.status != .completed {
            throw KilnError.conversionFailed("Video export did not complete")
        }
    }

    private static func posterFrame(input: URL, format: Format, spec: OutputSpec) throws -> URL {
        let asset = AVURLAsset(url: input)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let cg = try generator.copyCGImage(at: .zero, actualTime: nil)
        let out = OutputLocation.url(for: input, newExtension: format.preferredExtension, in: spec.destinationDirectory)
        try ImageEngine.write(image: cg, from: nil, destination: out, uti: format.utType.identifier as CFString, spec: spec)
        return out
    }
}
