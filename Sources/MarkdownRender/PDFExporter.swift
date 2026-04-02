import Foundation
import WebKit

enum PDFExporter {
    static func suggestedFileName(for sourceURL: URL) -> String {
        sourceURL.deletingPathExtension().lastPathComponent + ".pdf"
    }

    @MainActor
    static func export(webView: WKWebView, to destinationURL: URL) async throws {
        let configuration = WKPDFConfiguration()
        let data = try await withCheckedThrowingContinuation { continuation in
            webView.createPDF(configuration: configuration) { result in
                continuation.resume(with: result)
            }
        }

        try data.write(to: destinationURL, options: .atomic)
    }
}
