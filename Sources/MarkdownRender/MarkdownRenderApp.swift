import AppKit
import SwiftUI

@MainActor
final class MarkdownRenderAppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        AppState.shared.openDocuments(at: urls)
    }
}

@main
struct MarkdownRenderApp: App {
    @NSApplicationDelegateAdaptor(MarkdownRenderAppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        WindowGroup("MarkdownRender") {
            ContentView()
                .environmentObject(state)
                .frame(minWidth: 760, minHeight: 520)
        }
        .defaultSize(width: 1024, height: 768)
    }
}
