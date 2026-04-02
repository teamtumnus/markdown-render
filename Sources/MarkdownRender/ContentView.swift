import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            PreviewWebView(
                html: state.currentHTML,
                baseURL: state.previewBaseURL,
                revision: state.previewRevision,
                state: state
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Open") {
                    state.openDocument()
                }
                .keyboardShortcut("o")

                Button("Reload") {
                    state.reloadDocument()
                }
                .disabled(!state.canReload)
                .keyboardShortcut("r")

                Button("Export PDF") {
                    state.exportPDF()
                }
                .disabled(!state.canExport)
                .keyboardShortcut("e")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.titleText)
                    .font(.headline)

                Text(state.statusText)
                    .font(.subheadline)
                    .foregroundStyle(
                        state.errorText == nil
                            ? AnyShapeStyle(.secondary)
                            : AnyShapeStyle(.red)
                    )
                    .lineLimit(1)
            }

            Spacer()

            if state.isExporting {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }
}
