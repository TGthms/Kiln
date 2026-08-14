import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            AppModel.shared.importURLs(urls)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc func convertWithKiln(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
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
        guard !urls.isEmpty else { return }
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
            AppModel.shared.importURLs(urls)
        }
    }
}
