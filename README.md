# MarkdownRender

Minimal native macOS app for previewing Markdown files and exporting them as PDFs.

## Features

- Open local `.md` and `.markdown` files
- Register as a Finder "Open With" option for Markdown files once installed
- Render Markdown in a native SwiftUI app using WebKit
- Export the rendered preview to PDF
- Resolve relative image paths from the source file's folder

## Build

For local development:

```bash
swift run MarkdownRender
```

To build a local `.app` bundle:

```bash
./scripts/build_app.sh
```

The bundle is written to `dist/MarkdownRender.app`.

Replace the installed app in `/Applications` with the rebuilt bundle so macOS can refresh its file-handler metadata.

## Notes

- The renderer supports common Markdown syntax: headings, paragraphs, lists, blockquotes, code fences, links, images, bold, italic, inline code, and admonitions.
- Admonitions work with both `!!! note "Title"` blocks and GitHub-style callouts such as `> [!NOTE]`.
- The renderer is intentionally small and does not aim for full CommonMark compatibility.
- The build script ad-hoc signs the local app bundle. Developer ID signing and notarization are still required for warning-free distribution to other Macs.
