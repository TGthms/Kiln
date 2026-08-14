import Foundation
import AVFoundation

enum AudioEngine {
    static func convert(input: URL, to format: Format, spec: OutputSpec) throws -> URL {
        try OutputLocation.ensureDirectory(spec.destinationDirectory)
        let out = OutputLocation.url(for: input, newExtension: format.preferredExtension, in: spec.destinationDirectory)
        if format.requiresFFMPEG {
            return try FFmpegEngine.convert(input: input, output: out, format: format, spec: spec)
        }
        let preset = exportPreset(for: format)
        try export(input: input, output: out, preset: preset, fileType: fileType(for: format))
        return out
    }

    static func compress(input: URL, format: Format, spec: OutputSpec) throws -> URL {
        var next = spec
        next.quality = min(spec.quality, 0.5)
        return try convert(input: input, to: format, spec: next)
    }

    private static func fileType(for format: Format) -> AVFileType {
        switch format.id {
        case "wav": return .wav
        case "aiff": return .aiff
        case "caf": return .caf
        case "m4a": return .m4a
        case "mp4": return .mp4
        case "mov": return .mov
        default: return .m4a
        }
    }

    private static func exportPreset(for format: Format) -> String {
        switch format.id {
        case "wav", "aiff", "caf":
            return AVAssetExportPresetAppleM4A
        case "m4a":
            return AVAssetExportPresetAppleM4A
        default:
            return AVAssetExportPresetAppleM4A
        }
    }

    private static func export(input: URL, output: URL, preset: String, fileType: AVFileType) throws {
        let asset = AVURLAsset(url: input)
        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw KilnError.conversionFailed("No audio export session")
        }
        session.outputURL = output
        session.outputFileType = fileType
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
            throw KilnError.conversionFailed("Audio export did not complete")
        }
    }
}
