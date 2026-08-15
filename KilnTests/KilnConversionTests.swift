import XCTest
import Foundation
import AppKit
import PDFKit
import ImageIO
import UniformTypeIdentifiers
@testable import Kiln

final class KilnConversionTests: XCTestCase {
    var scratch: URL!
    let service = ConversionService()

    override func setUpWithError() throws {
        scratch = FileManager.default.temporaryDirectory.appendingPathComponent("kiln-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: scratch)
    }

    func testIdentifyFixtures() throws {
        XCTAssertEqual(service.identify(url: fixture("sample.png"))?.id, "png")
        XCTAssertEqual(service.identify(url: fixture("sample.jpg"))?.id, "jpeg")
        XCTAssertEqual(service.identify(url: fixture("sample.pdf"))?.id, "pdf")
        XCTAssertEqual(service.identify(url: fixture("sample.json"))?.id, "json")
    }

    func testConvertPNGToJPEG() throws {
        let source = fixture("sample.png")
        let before = try checksum(source)
        let spec = OutputSpec(mode: .convert, formatID: "jpeg", quality: 0.8, destinationDirectory: scratch)
        let out = try service.convert(input: source, to: "jpeg", spec: spec)
        XCTAssertTrue(FileManager.default.fileExists(atPath: out.path))
        XCTAssertTrue(isJPEG(out))
        XCTAssertEqual(try checksum(source), before)
        XCTAssertNotEqual(out.lastPathComponent, source.lastPathComponent)
    }

    func testConvertJPEGToPNG() throws {
        let source = fixture("sample.jpg")
        let before = try checksum(source)
        let spec = OutputSpec(mode: .convert, formatID: "png", destinationDirectory: scratch)
        let out = try service.convert(input: source, to: "png", spec: spec)
        XCTAssertTrue(isPNG(out))
        XCTAssertEqual(try checksum(source), before)
    }

    func testConvertPNGToPDF() throws {
        let source = fixture("sample.png")
        let spec = OutputSpec(mode: .convert, formatID: "pdf", destinationDirectory: scratch)
        let out = try service.convert(input: source, to: "pdf", spec: spec)
        XCTAssertTrue(isPDF(out))
        let doc = try XCTUnwrap(PDFDocument(url: out))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 1)
    }

    func testConvertPDFPagesToPNG() throws {
        let source = fixture("sample.pdf")
        let spec = OutputSpec(mode: .convert, formatID: "png", destinationDirectory: scratch)
        let out = try service.convert(input: source, to: "png", spec: spec)
        XCTAssertTrue(isPNG(out))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    func testCompressJPEGIsSmaller() throws {
        let source = fixture("sample.jpg")
        let inputSize = try fileSize(source)
        XCTAssertGreaterThan(inputSize, 50_000)
        let spec = OutputSpec(mode: .compress, quality: 0.22, maxDimension: 1280, destinationDirectory: scratch)
        let out = try service.compress(input: source, spec: spec)
        XCTAssertTrue(isJPEG(out))
        let outputSize = try fileSize(out)
        XCTAssertLessThan(outputSize, inputSize, "compress should shrink \(outputSize) vs \(inputSize)")
        XCTAssertEqual(try fileSize(source), inputSize)
    }

    func testCompressPNGSmallestIsSmaller() throws {
        let source = fixture("sample.png")
        let inputSize = try fileSize(source)
        var spec = OutputSpec(mode: .compress, formatID: "jpeg", quality: KilnPreset.smallest.quality, maxDimension: KilnPreset.smallest.maxDimension, destinationDirectory: scratch)
        let out = try service.compress(input: source, spec: spec)
        let outputSize = try fileSize(out)
        XCTAssertLessThan(outputSize, inputSize)
        XCTAssertTrue(isJPEG(out) || isPNG(out))
    }

    func testCombineImagesToPDF() throws {
        let png = fixture("sample.png")
        let jpg = fixture("sample.jpg")
        let spec = OutputSpec(mode: .combine, formatID: "pdf", destinationDirectory: scratch)
        let out = try service.combine(inputs: [png, jpg], spec: spec)
        XCTAssertTrue(isPDF(out))
        let doc = try XCTUnwrap(PDFDocument(url: out))
        XCTAssertGreaterThanOrEqual(doc.pageCount, 2)
    }

    func testSplitPDFProducesOneFilePerPage() throws {
        let source = fixture("sample.pdf")
        let doc = try XCTUnwrap(PDFDocument(url: source))
        XCTAssertEqual(doc.pageCount, 2)
        let spec = OutputSpec(mode: .split, formatID: "pdf", destinationDirectory: scratch)
        let outs = try service.split(input: source, spec: spec)
        XCTAssertEqual(outs.count, doc.pageCount)
        for url in outs {
            XCTAssertTrue(isPDF(url))
            XCTAssertEqual(PDFDocument(url: url)?.pageCount, 1)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    func testCombineOffersPDFAndZip() throws {
        let png = try XCTUnwrap(service.identify(url: fixture("sample.png")))
        let dests = ConversionGraph().destinations(from: png, mode: .combine)
        XCTAssertTrue(dests.contains(where: { $0.id == "pdf" }))
        XCTAssertTrue(dests.contains(where: { $0.id == "zip" }))
    }

    func testDestinationsAreRunnableOnly() throws {
        let png = try XCTUnwrap(service.identify(url: fixture("sample.png")))
        let dests = ConversionGraph().destinations(from: png, mode: .convert)
        XCTAssertTrue(dests.contains(where: { $0.id == "jpeg" }))
        XCTAssertTrue(dests.contains(where: { $0.id == "pdf" }))
        XCTAssertFalse(dests.contains(where: { $0.id == "png" }))
        for dest in dests {
            XCTAssertTrue(dest.canWrite)
        }
    }

    func testJSONToYAML() throws {
        let source = fixture("sample.json")
        let spec = OutputSpec(mode: .convert, formatID: "yaml", destinationDirectory: scratch)
        let out = try service.convert(input: source, to: "yaml", spec: spec)
        let text = try String(contentsOf: out, encoding: .utf8)
        XCTAssertTrue(text.contains("hello"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    func testClaimSingleFileDoesNotPullSiblingsFromParentFolder() throws {
        let folder = scratch.appendingPathComponent("album")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixture("sample.jpg"), to: folder.appendingPathComponent("photo.jpg"))
        try FileManager.default.copyItem(at: fixture("sample.png"), to: folder.appendingPathComponent("other.png"))
        try FileManager.default.copyItem(at: fixture("sample.pdf"), to: folder.appendingPathComponent("notes.pdf"))
        try FileManager.default.copyItem(at: fixture("sample.json"), to: folder.appendingPathComponent("meta.json"))
        let one = folder.appendingPathComponent("photo.jpg")
        let inbox = scratch.appendingPathComponent("single-inbox")

        let owned = FileImport.claim([one], into: inbox)
        XCTAssertEqual(owned.count, 1, "one file must not enqueue siblings in the parent folder")
        XCTAssertEqual(owned[0].lastPathComponent, "photo.jpg")
        XCTAssertEqual(service.identify(url: owned[0])?.id, "jpeg")

        let prepared = FileImport.ingest(
            urls: [one],
            already: [],
            inbox: scratch.appendingPathComponent("ingest-inbox"),
            identify: { service.identify(url: $0) }
        )
        XCTAssertEqual(prepared.count, 1)
        XCTAssertEqual(prepared[0].format?.id, "jpeg")

        let dests = service.destinations(for: owned, mode: .convert)
        XCTAssertFalse(dests.isEmpty, "Convert must offer format targets after a single-file import")
        XCTAssertFalse(dests.contains(where: { $0.id == "jpeg" }), "same-as-source is not a convert target")
        XCTAssertTrue(dests.contains(where: { $0.id == "png" }))
        XCTAssertTrue(
            ConversionReadiness.canStart(
                runnableCount: owned.count,
                destinationID: dests.first?.id,
                mode: .convert,
                isRunning: false
            )
        )

        let narrowed = FileImport.narrowToDroppedFile(folder, suggestedName: "photo.jpg")
        XCTAssertEqual(narrowed.lastPathComponent, "photo.jpg")
        XCTAssertFalse(FileImport.isDirectory(narrowed))
        let fromParentHint = FileImport.claim([narrowed], into: scratch.appendingPathComponent("hint-inbox"))
        XCTAssertEqual(fromParentHint.count, 1)
        XCTAssertEqual(fromParentHint[0].lastPathComponent, "photo.jpg")

        let collapsed = FileImport.withoutDirectoryAncestors([folder, one])
        XCTAssertEqual(collapsed.count, 1)
        XCTAssertEqual(collapsed[0].lastPathComponent, "photo.jpg")
        let claimedCollapsed = FileImport.claim([folder, one], into: scratch.appendingPathComponent("collapse-inbox"))
        XCTAssertEqual(claimedCollapsed.count, 1)

        let folderDrop = FileImport.claim([folder], into: scratch.appendingPathComponent("folder-inbox"))
        XCTAssertEqual(folderDrop.count, 4, "explicit folder drop still flattens")
    }

    func testConvertAfterSingleFileImportWritesNewFormat() throws {
        let folder = scratch.appendingPathComponent("src")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let original = folder.appendingPathComponent("photo.jpg")
        try FileManager.default.copyItem(at: fixture("sample.jpg"), to: original)
        let before = try checksum(original)
        let owned = FileImport.claim([original], into: scratch.appendingPathComponent("convert-inbox"))
        XCTAssertEqual(owned.count, 1)
        let dests = service.destinations(for: owned, mode: .convert)
        let png = try XCTUnwrap(dests.first(where: { $0.id == "png" }))
        XCTAssertNotEqual(png.id, "jpeg")
        let spec = OutputSpec(mode: .convert, formatID: png.id, destinationDirectory: scratch)
        let out = try service.convert(input: owned[0], to: png.id, spec: spec)
        XCTAssertTrue(FileManager.default.fileExists(atPath: out.path))
        XCTAssertTrue(isPNG(out))
        XCTAssertEqual(try checksum(original), before, "original must not be overwritten")
        XCTAssertNotEqual(out.standardizedFileURL.path, original.standardizedFileURL.path)
        XCTAssertNotEqual(out.standardizedFileURL.path, owned[0].standardizedFileURL.path)
    }

    func testShippedImportAcceptsFixturesWithoutCrashing() throws {
        let png = fixture("sample.png")
        let jpg = fixture("sample.jpg")
        let pdf = fixture("sample.pdf")
        let inbox = scratch.appendingPathComponent("inbox")
        let prepared = FileImport.ingest(
            urls: [png, jpg, pdf, png],
            already: [],
            inbox: inbox,
            identify: { service.identify(url: $0) }
        )
        XCTAssertEqual(prepared.count, 3)
        XCTAssertEqual(prepared[0].format?.id, "png")
        XCTAssertEqual(prepared[1].format?.id, "jpeg")
        XCTAssertEqual(prepared[2].format?.id, "pdf")
        for pair in prepared {
            XCTAssertTrue(FileManager.default.fileExists(atPath: pair.url.path))
            XCTAssertTrue(pair.url.path.contains("inbox"))
        }
        let dests = service.destinations(for: prepared.map(\.url), mode: .convert)
        XCTAssertFalse(dests.isEmpty)
        XCTAssertTrue(
            ConversionReadiness.canStart(
                runnableCount: prepared.count,
                destinationID: dests.first?.id,
                mode: .convert,
                isRunning: false
            )
        )
        XCTAssertFalse(
            ConversionReadiness.canStart(
                runnableCount: prepared.count,
                destinationID: dests.first?.id,
                mode: .convert,
                isRunning: true
            )
        )
    }

    /// AppDelegate.application(_:open:), convertWithKiln, browse(), and drop all
    /// call `FileImport.claim` on the incoming URLs *before* hopping to main.
    func testOpenWithAndServicesClaimBeforeHopThenIdentify() throws {
        let png = fixture("sample.png")
        let jpg = fixture("sample.jpg")
        let pdf = fixture("sample.pdf")
        let inbox = scratch.appendingPathComponent("open-inbox")
        let owned = FileImport.claim([png, jpg, pdf, png], into: inbox)
        XCTAssertEqual(owned.count, 3)
        for copy in owned {
            XCTAssertTrue(copy.path.hasPrefix(inbox.path), "hop must carry inbox copies, not originals")
            XCTAssertNotEqual(copy.standardizedFileURL.path, png.standardizedFileURL.path)
            XCTAssertTrue(FileManager.default.isReadableFile(atPath: copy.path))
        }
        XCTAssertEqual(service.identify(url: owned[0])?.id, "png")
        XCTAssertEqual(service.identify(url: owned[1])?.id, "jpeg")
        XCTAssertEqual(service.identify(url: owned[2])?.id, "pdf")
        let dests = service.destinations(for: owned, mode: .convert)
        XCTAssertTrue(
            ConversionReadiness.canStart(
                runnableCount: owned.count,
                destinationID: dests.first?.id,
                mode: .convert,
                isRunning: false
            )
        )
    }

    func testAdoptIncomingFailsClosedWhenCopyImpossible() throws {
        let source = fixture("sample.jpg")
        let notADirectory = scratch.appendingPathComponent("not-a-dir")
        try Data("x".utf8).write(to: notADirectory)
        let result = FileImport.adoptIncoming(source, into: notADirectory)
        XCTAssertNil(result, "must not hand the original scoped URL to code after the callback")
        let claimed = FileImport.claim([source], into: notADirectory)
        XCTAssertTrue(claimed.isEmpty)
        XCTAssertNil(FileImport.adoptIncoming(scratch.appendingPathComponent("missing.jpg"), into: scratch.appendingPathComponent("inbox")))
    }

    func testServicesPasteboardClaimThenIdentify() throws {
        let file = fixture("sample.png")
        let pboard = NSPasteboard.withUniqueName()
        pboard.clearContents()
        XCTAssertTrue(pboard.writeObjects([file as NSURL]))
        let parsed = ServiceImport.urls(from: pboard)
        XCTAssertEqual(parsed.map(\.standardizedFileURL.path), [file.standardizedFileURL.path])
        let inbox = scratch.appendingPathComponent("services-inbox")
        let owned = FileImport.claim(parsed, into: inbox)
        XCTAssertEqual(owned.count, 1)
        XCTAssertTrue(owned[0].path.hasPrefix(inbox.path))
        XCTAssertEqual(service.identify(url: owned[0])?.id, "png")
    }

    @MainActor
    func testDropEnqueueCopiesAndThumbnailsWithoutIsolationCrash() async throws {
        let file = fixture("sample.jpg")
        let provider = try XCTUnwrap(NSItemProvider(contentsOf: file))
        let owned: [URL] = await withCheckedContinuation { continuation in
            DropImport.enqueue([provider]) { urls in
                continuation.resume(returning: urls)
            }
        }
        XCTAssertEqual(owned.count, 1)
        XCTAssertNotEqual(owned[0].standardizedFileURL.path, file.standardizedFileURL.path)
        XCTAssertEqual(service.identify(url: owned[0])?.id, "jpeg")
        let image = await Task.detached { ThumbnailLoader.make(at: owned[0]) }.value
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
    }

    func testClaimThenThumbnailOffMainDoesNotCrash() throws {
        let inbox = scratch.appendingPathComponent("thumb-inbox")
        let owned = FileImport.claim(
            [fixture("sample.png"), fixture("sample.jpg"), fixture("sample.pdf")],
            into: inbox
        )
        XCTAssertEqual(owned.count, 3)
        let exp = expectation(description: "thumbnails")
        exp.expectedFulfillmentCount = owned.count
        for url in owned {
            DispatchQueue.global(qos: .userInitiated).async {
                let image = ThumbnailLoader.make(at: url)
                XCTAssertNotNil(image, url.lastPathComponent)
                XCTAssertGreaterThan(image?.size.width ?? 0, 0)
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 8)
    }

    func testClaimFlattensFolderWhileAccessed() throws {
        let folder = scratch.appendingPathComponent("open-folder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixture("sample.png"), to: folder.appendingPathComponent("a.png"))
        try FileManager.default.copyItem(at: fixture("sample.jpg"), to: folder.appendingPathComponent("b.jpg"))
        let inbox = scratch.appendingPathComponent("folder-inbox")
        let owned = FileImport.claim([folder], into: inbox)
        XCTAssertEqual(Set(owned.map(\.lastPathComponent)), ["a.png", "b.jpg"])
        XCTAssertTrue(owned.allSatisfy { $0.path.hasPrefix(inbox.path) })
        XCTAssertEqual(service.identify(url: owned.first { $0.pathExtension == "png" }!)?.id, "png")
    }

    func testCollectFilesFlattensDirectoryIteratively() throws {
        let folder = scratch.appendingPathComponent("drop-folder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixture("sample.png"), to: folder.appendingPathComponent("a.png"))
        try FileManager.default.copyItem(at: fixture("sample.jpg"), to: folder.appendingPathComponent("b.jpg"))
        let files = FileImport.collectFiles(from: [folder], already: [])
        XCTAssertEqual(Set(files.map(\.lastPathComponent)), ["a.png", "b.jpg"])
    }

    func testResolveProviderItemAcceptsFileURLData() {
        let file = fixture("sample.png")
        XCTAssertEqual(FileImport.resolveProviderItem(file)?.path, file.path)
        let data = file.dataRepresentation
        XCTAssertEqual(FileImport.resolveProviderItem(data)?.path, file.path)
        XCTAssertNil(FileImport.resolveProviderItem("not a path"))
    }

    func testDoesNotOverwriteOriginal() throws {
        let source = fixture("sample.jpg")
        let copy = scratch.appendingPathComponent("sample.jpg")
        try FileManager.default.copyItem(at: source, to: copy)
        let before = try checksum(copy)
        let spec = OutputSpec(mode: .convert, formatID: "png", destinationDirectory: scratch)
        let out = try service.convert(input: copy, to: "png", spec: spec)
        XCTAssertNotEqual(out.path, copy.path)
        XCTAssertEqual(try checksum(copy), before)
        XCTAssertTrue(FileManager.default.fileExists(atPath: copy.path))
    }

    func testLocaleCatalogComplete() throws {
        let catalogURL = localizationCatalog()
        let data = try Data(contentsOf: catalogURL)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let strings = try XCTUnwrap(json["strings"] as? [String: Any])
        XCTAssertFalse(strings.isEmpty)
        let required = Set(AppLanguage.shippedCodes)
        XCTAssertEqual(required.count, 30)
        XCTAssertTrue(required.contains("pt-BR"))
        XCTAssertTrue(required.contains("pt-PT"))
        XCTAssertTrue(required.contains("zh-Hans"))
        XCTAssertTrue(required.contains("zh-Hant"))
        XCTAssertTrue(required.contains("ar"))
        XCTAssertTrue(required.contains("he"))

        var failures: [String] = []
        for (key, raw) in strings {
            guard let entry = raw as? [String: Any],
                  let locs = entry["localizations"] as? [String: Any] else {
                failures.append("\(key): missing localizations")
                continue
            }
            for locale in required {
                guard let payload = locs[locale] as? [String: Any] else {
                    failures.append("\(key)/\(locale): missing")
                    continue
                }
                if let unit = payload["stringUnit"] as? [String: Any] {
                    let value = (unit["value"] as? String) ?? ""
                    if value.isEmpty { failures.append("\(key)/\(locale): empty") }
                } else if let variations = payload["variations"] as? [String: Any],
                          let plural = variations["plural"] as? [String: Any] {
                    guard let other = plural["other"] as? [String: Any],
                          let unit = other["stringUnit"] as? [String: Any],
                          let value = unit["value"] as? String, !value.isEmpty else {
                        failures.append("\(key)/\(locale): empty plural")
                        continue
                    }
                } else {
                    failures.append("\(key)/\(locale): no value")
                }
            }
            if key.contains("drop.title") || key == "drop.title" {
                let en = stringValue(locs["en"] as? [String: Any])
                let ptBR = stringValue(locs["pt-BR"] as? [String: Any])
                let ptPT = stringValue(locs["pt-PT"] as? [String: Any])
                let hans = stringValue(locs["zh-Hans"] as? [String: Any])
                let hant = stringValue(locs["zh-Hant"] as? [String: Any])
                XCTAssertNotEqual(ptBR, ptPT, "pt-BR must differ from pt-PT")
                XCTAssertNotEqual(hans, hant, "zh-Hans must differ from zh-Hant")
                XCTAssertNotEqual(en, hans)
            }
        }
        XCTAssertTrue(failures.isEmpty, "Incomplete catalog:\n" + failures.prefix(40).joined(separator: "\n"))
    }

    func testFormatCodesUntranslated() {
        XCTAssertEqual(FormatCatalog.shared.format(id: "jpeg")?.displayName, "JPEG")
        XCTAssertEqual(FormatCatalog.shared.format(id: "pdf")?.displayName, "PDF")
        XCTAssertEqual(FormatCatalog.shared.format(id: "heic")?.displayName, "HEIC")
    }

    func testImageWriteFlagClearsWhenDestinationUTIMissing() {
        let webp = Format(
            id: "webp",
            displayName: "WebP",
            utType: UTType("org.webmproject.webp") ?? UTType(filenameExtension: "webp") ?? .data,
            extensions: ["webp"],
            family: .image,
            canRead: true,
            canWrite: true,
            requiresFFMPEG: false,
            lossy: true
        )
        let png = Format(
            id: "png",
            displayName: "PNG",
            utType: .png,
            extensions: ["png"],
            family: .image,
            canRead: true,
            canWrite: true,
            requiresFFMPEG: false,
            lossy: false
        )
        var list = [webp, png]
        FormatCatalog.applyImageWriteCapabilities(&list, destIDs: ["public.png"])
        XCTAssertFalse(list[0].canWrite, "WebP must not stay writable when ImageIO cannot encode it")
        XCTAssertTrue(list[1].canWrite)
    }

    func testLiveCatalogImageWriteMatchesImageIO() {
        let destIDs = FormatCatalog.imageDestinationIdentifiers()
        let catalog = FormatCatalog.shared
        for id in ["webp", "avif", "jpeg", "png", "heic"] {
            guard let format = catalog.format(id: id) else { continue }
            XCTAssertEqual(
                format.canWrite,
                destIDs.contains(format.utType.identifier),
                "\(id) canWrite must follow CGImageDestination UTIs"
            )
        }
        let png = try! XCTUnwrap(catalog.format(id: "png"))
        let dests = ConversionGraph(catalog: catalog).destinations(from: png, mode: .convert)
        if let webp = catalog.format(id: "webp"), !webp.canWrite {
            XCTAssertFalse(dests.contains(where: { $0.id == "webp" }))
        }
        XCTAssertTrue(dests.allSatisfy(\.canWrite))
    }

    func testXLSXDestinationsMatchOfficeEngine() throws {
        let xlsx = try XCTUnwrap(FormatCatalog.shared.format(id: "xlsx"))
        let graph = ConversionGraph()
        let dests = graph.destinations(from: xlsx, mode: .convert)
        let ids = Set(dests.map(\.id))
        XCTAssertEqual(Set(graph.convertTargetIDs(fromDocument: xlsx)), ["csv", "json", "tsv", "txt"])
        XCTAssertTrue(ids.isSubset(of: ["csv", "json", "tsv", "txt"]))
        XCTAssertTrue(ids.contains("csv"))
        XCTAssertTrue(ids.contains("json"))
        XCTAssertFalse(ids.contains("rtf"))
        XCTAssertFalse(ids.contains("html"))
        XCTAssertFalse(ids.contains("markdown"))
        XCTAssertFalse(ids.contains("pdf"))
        XCTAssertTrue(dests.allSatisfy(\.canWrite))
    }

    func testConvertRejectsDestinationGraphDoesNotOffer() throws {
        let source = fixture("sample.json")
        let spec = OutputSpec(mode: .convert, formatID: "docx", destinationDirectory: scratch)
        XCTAssertThrowsError(try service.convert(input: source, to: "docx", spec: spec))
    }

    func testAudioDestinationsAreEncodable() throws {
        let wav = try XCTUnwrap(FormatCatalog.shared.format(id: "wav"))
        XCTAssertFalse(wav.canWrite)
        let dests = ConversionGraph().destinations(from: wav, mode: .convert)
        XCTAssertFalse(dests.contains(where: { $0.id == "wav" }))
        XCTAssertFalse(dests.contains(where: { $0.id == "aiff" }))
        XCTAssertFalse(dests.contains(where: { $0.id == "caf" }))
        XCTAssertTrue(dests.contains(where: { $0.id == "m4a" }))
        XCTAssertTrue(dests.allSatisfy(\.canWrite))
        XCTAssertFalse(FormatCatalog.shared.format(id: "aiff")?.canWrite ?? true)
        XCTAssertFalse(FormatCatalog.shared.format(id: "caf")?.canWrite ?? true)
    }

    func testImportIdentityKeyCollapsesPathVariants() {
        let a = URL(fileURLWithPath: "/tmp/kiln-sample.png")
        let b = URL(fileURLWithPath: "/tmp/./kiln-sample.png")
        XCTAssertEqual(FileImport.identityKey(for: a), FileImport.identityKey(for: b))
    }

    func testImportURLsDedupesTheSameFile() {
        let url = fixture("sample.png")
        let duplicate = URL(fileURLWithPath: url.path + "/../" + url.lastPathComponent)
        let unique = FileImport.uniqueNew(urls: [url, url, duplicate], already: [])
        XCTAssertEqual(unique.count, 1, "one Finder drop / duplicate URL must not enqueue twice")
        let again = FileImport.uniqueNew(urls: [url], already: unique)
        XCTAssertTrue(again.isEmpty)
    }

    func testCopyrightNamesTGthms() throws {
        let data = try Data(contentsOf: localizationCatalog())
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let strings = try XCTUnwrap(json["strings"] as? [String: Any])
        let entry = try XCTUnwrap(strings["settings.copyright"] as? [String: Any])
        let locs = try XCTUnwrap(entry["localizations"] as? [String: Any])
        let en = stringValue(locs["en"] as? [String: Any])
        XCTAssertTrue(en.contains("TGthms"), "Settings copyright must name TGthms")
        XCTAssertTrue(en.lowercased().contains("copyright"))
        let plist = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Kiln/Resources/Info.plist")
        let info = try XCTUnwrap(NSDictionary(contentsOf: plist))
        let human = try XCTUnwrap(info["NSHumanReadableCopyright"] as? String)
        XCTAssertTrue(human.contains("TGthms"))
    }

    func testRTLLanguagesAreMarked() {
        XCTAssertTrue(AppLanguage.ar.isRTL)
        XCTAssertTrue(AppLanguage.he.isRTL)
        XCTAssertFalse(AppLanguage.en.isRTL)
        XCTAssertFalse(AppLanguage.ja.isRTL)
    }

    // MARK: - helpers

    private func fixture(_ name: String) -> URL {
        if let bundled = Bundle(for: KilnConversionTests.self).url(forResource: name, withExtension: nil) {
            return bundled
        }
        if let bundled = Bundle(for: KilnConversionTests.self).url(forResource: (name as NSString).deletingPathExtension, withExtension: (name as NSString).pathExtension) {
            return bundled
        }
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root.appendingPathComponent("Fixtures").appendingPathComponent(name)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "missing fixture \(url.path)")
        return url
    }

    private func localizationCatalog() -> URL {
        let bundle = Bundle(for: KilnConversionTests.self)
        if let bundled = bundle.url(forResource: "Localizable.catalog", withExtension: "json") {
            return bundled
        }
        if let bundled = bundle.url(forResource: "Localizable", withExtension: "catalog.json") {
            return bundled
        }
        XCTFail("Localizable.catalog.json missing from test bundle")
        return URL(fileURLWithPath: "/nonexistent")
    }

    private func checksum(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return SHALike.hash(data)
    }

    private func fileSize(_ url: URL) throws -> Int {
        try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? -1
    }

    private func isJPEG(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url), data.count > 3 else { return false }
        return data[0] == 0xFF && data[1] == 0xD8
    }

    private func isPNG(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url), data.count > 4 else { return false }
        return data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47
    }

    private func isPDF(_ url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url), data.count > 4 else { return false }
        return data.starts(with: [0x25, 0x50, 0x44, 0x46])
    }

    private func stringValue(_ payload: [String: Any]?) -> String {
        ((payload?["stringUnit"] as? [String: Any])?["value"] as? String) ?? ""
    }
}

private enum SHALike {
    static func hash(_ data: Data) -> String {
        var hash: UInt64 = 14695981039346656037
        for b in data {
            hash ^= UInt64(b)
            hash &*= 1099511628211
        }
        return String(hash, radix: 16)
    }
}
