import AppKit

/// Finder Services pasteboard → file URLs. `convertWithKiln` claims these
/// **before** hopping to the main actor.
enum ServiceImport {
    static func urls(from pboard: NSPasteboard) -> [URL] {
        var urls: [URL] = []
        if let items = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            urls.append(contentsOf: items)
        }
        if urls.isEmpty, let paths = pboard.propertyList(forType: .fileURL) {
            if let data = paths as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                urls.append(url)
            }
        }
        if urls.isEmpty, let list = pboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            urls.append(contentsOf: list.map { URL(fileURLWithPath: $0) })
        }
        return urls
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let owned = FileImport.claim(urls)
        Task { @MainActor in
            AppModel.shared.importURLs(owned)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc func convertWithKiln(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
        let owned = FileImport.claim(ServiceImport.urls(from: pboard))
        guard !owned.isEmpty else { return }
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
            AppModel.shared.importURLs(owned)
        }
    }
}
