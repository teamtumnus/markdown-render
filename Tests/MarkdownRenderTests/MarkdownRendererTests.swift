import XCTest
@testable import MarkdownRender

final class MarkdownRendererTests: XCTestCase {
    func testRendererPreservesCommonMarkdownShapes() throws {
        let markdown = """
        # Title

        A paragraph with **bold**, *italic*, [a link](https://example.com), and `code`.

        - one
        - two

        ```swift
        print("hi")
        ```
        """

        let html = try MarkdownRenderer.render(markdown: markdown, fileURL: URL(fileURLWithPath: "/tmp/Notes.md"))

        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
        XCTAssertTrue(html.contains("<em>italic</em>"))
        XCTAssertTrue(html.contains("<a href=\"https://example.com\">a link</a>"))
        XCTAssertTrue(html.contains("<code>code</code>"))
        XCTAssertTrue(html.contains("<ul><li>one</li><li>two</li></ul>"))
        XCTAssertTrue(html.contains("<pre><code class=\"language-swift\">print(\"hi\")</code></pre>"))
    }

    func testRendererKeepsImagesAndBlockquotes() throws {
        let markdown = """
        > Quoted **text**

        ![Alt text](images/diagram.png)
        """

        let html = try MarkdownRenderer.render(markdown: markdown, fileURL: nil)

        XCTAssertTrue(html.contains("<blockquote><p>Quoted <strong>text</strong></p></blockquote>"))
        XCTAssertTrue(html.contains("<img src=\"images/diagram.png\" alt=\"Alt text\">"))
    }

    func testRendererSupportsFencedAdmonitions() throws {
        let markdown = """
        !!! note "Heads up"
            This supports **admonitions** too.

            - first
            - second
        """

        let html = try MarkdownRenderer.render(markdown: markdown, fileURL: nil)

        XCTAssertTrue(html.contains("<section class=\"admonition admonition-note\">"))
        XCTAssertTrue(html.contains("<p class=\"admonition-title\">Heads up</p>"))
        XCTAssertTrue(html.contains("<p>This supports <strong>admonitions</strong> too.</p>"))
        XCTAssertTrue(html.contains("<ul><li>first</li><li>second</li></ul>"))
    }

    func testRendererSupportsGitHubStyleCallouts() throws {
        let markdown = """
        > [!WARNING] Read this first
        > Exporting may overwrite the previous PDF.
        >
        > Keep a backup.
        """

        let html = try MarkdownRenderer.render(markdown: markdown, fileURL: nil)

        XCTAssertTrue(html.contains("<section class=\"admonition admonition-warning\">"))
        XCTAssertTrue(html.contains("<p class=\"admonition-title\">Read this first</p>"))
        XCTAssertTrue(html.contains("<p>Exporting may overwrite the previous PDF.</p>"))
        XCTAssertTrue(html.contains("<p>Keep a backup.</p>"))
    }

    func testSuggestedFileNameUsesPdfExtension() {
        let firstURL = URL(fileURLWithPath: "/tmp/notes.md")
        let secondURL = URL(fileURLWithPath: "/tmp/README.markdown")

        XCTAssertEqual(PDFExporter.suggestedFileName(for: firstURL), "notes.pdf")
        XCTAssertEqual(PDFExporter.suggestedFileName(for: secondURL), "README.pdf")
    }
}
