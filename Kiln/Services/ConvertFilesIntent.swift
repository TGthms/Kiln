import AppIntents
import Foundation

struct ConvertFilesIntent: AppIntent {
    static var title: LocalizedStringResource { "Convert with Kiln" }
    static var description: IntentDescription { IntentDescription("Send files into Kiln to convert them.") }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Files")
    var files: [IntentFile]

    func perform() async throws -> some IntentResult {
        let urls = files.compactMap { file -> URL? in
            if let url = file.fileURL { return url }
            let temp = FileManager.default.temporaryDirectory.appendingPathComponent(file.filename)
            try? file.data.write(to: temp)
            return temp
        }
        await MainActor.run {
            AppModel.shared.importURLs(urls)
        }
        return .result()
    }
}
