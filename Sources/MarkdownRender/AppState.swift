import AppKit
import Foundation
import UniformTypeIdentifiers
import WebKit

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published private(set) var currentFileURL: URL?
    @Published private(set) var currentHTML: String
    @Published private(set) var statusText = "Open a Markdown file to get started."
    @Published private(set) var errorText: String?
    @Published private(set) var isPreviewReady = false
    @Published private(set) var isExporting = false
    @Published private(set) var previewRevision = 0

    weak var webView: WKWebView?
    private var pendingOpenNote: String?

    private init() {
        currentHTML = MarkdownRenderer.placeholderHTML()
    }

    var titleText: String {
        currentFileURL?.lastPathComponent ?? "MarkdownRender"
    }

    var previewBaseURL: URL? {
        currentFileURL?.deletingLastPathComponent()
    }

    var canReload: Bool {
        currentFileURL != nil && !isExporting
    }

    var canExport: Bool {
        currentFileURL != nil && webView != nil && isPreviewReady && !isExporting
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = supportedDocumentTypes

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        openDocument(at: url)
    }

    func openDocument(at url: URL) {
        pendingOpenNote = nil
        loadDocument(from: url)
    }

    func openDocuments(at urls: [URL]) {
        let fileURLs = urls.filter(\.isFileURL)

        guard let firstURL = fileURLs.first else {
            presentError(
                title: "Could not open selection",
                details: "MarkdownRender can only open local Markdown files."
            )
            return
        }

        pendingOpenNote = fileURLs.count > 1 ? "Opened the first of \(fileURLs.count) files." : nil
        loadDocument(from: firstURL)
    }

    func reloadDocument() {
        guard let url = currentFileURL else {
            NSSound.beep()
            return
        }

        loadDocument(from: url)
    }

    func startPreviewLoad() {
        isPreviewReady = false
    }

    func finishPreviewLoad() {
        isPreviewReady = true
        errorText = nil
        if let url = currentFileURL {
            var status = "Previewing \(url.lastPathComponent)"
            if let pendingOpenNote {
                status += " • \(pendingOpenNote)"
                self.pendingOpenNote = nil
            }
            statusText = status
        }
    }

    func failPreviewLoad(_ message: String) {
        isPreviewReady = false
        errorText = message
        statusText = message
    }

    func attach(webView: WKWebView) {
        self.webView = webView
    }

    func exportPDF() {
        Task {
            await exportPDFToChosenLocation()
        }
    }

    private func loadDocument(from url: URL) {
        do {
            let markdown = try readMarkdown(at: url)
            currentHTML = try MarkdownRenderer.render(markdown: markdown, fileURL: url)
            currentFileURL = url
            errorText = nil
            statusText = "Loading \(url.lastPathComponent)..."
            isPreviewReady = false
            previewRevision += 1
        } catch {
            currentFileURL = url
            presentError(
                title: "Could not open \(url.lastPathComponent)",
                details: error.localizedDescription
            )
        }
    }

    private func exportPDFToChosenLocation() async {
        guard let sourceURL = currentFileURL else {
            presentError(title: "No file loaded", details: "Open a Markdown file before exporting.")
            return
        }

        guard let webView else {
            presentError(title: "Preview unavailable", details: "Wait for the preview to finish loading.")
            return
        }

        guard isPreviewReady else {
            presentError(title: "Preview still loading", details: "Wait for the preview to finish before exporting.")
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = PDFExporter.suggestedFileName(for: sourceURL)

        guard panel.runModal() == .OK, let destinationURL = panel.url else {
            return
        }

        isExporting = true
        statusText = "Exporting \(destinationURL.lastPathComponent)..."

        do {
            try await PDFExporter.export(webView: webView, to: destinationURL)
            errorText = nil
            statusText = "Exported \(destinationURL.lastPathComponent)"
        } catch {
            presentError(
                title: "PDF export failed",
                details: error.localizedDescription
            )
        }

        isExporting = false
    }

    private func presentError(title: String, details: String) {
        currentHTML = MarkdownRenderer.errorHTML(title: title, message: details)
        errorText = details
        statusText = title
        isPreviewReady = false
        pendingOpenNote = nil
        previewRevision += 1
    }

    private func readMarkdown(at url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        if let markdown = String(data: data, encoding: .utf8) {
            return markdown
        }

        return String(decoding: data, as: UTF8.self)
    }

    private var supportedDocumentTypes: [UTType] {
        [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
        ]
    }
}
