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

    func testSuggestedFileNameUsesPdfExtension() {
        let firstURL = URL(fileURLWithPath: "/tmp/notes.md")
        let secondURL = URL(fileURLWithPath: "/tmp/README.markdown")

        XCTAssertEqual(PDFExporter.suggestedFileName(for: firstURL), "notes.pdf")
        XCTAssertEqual(PDFExporter.suggestedFileName(for: secondURL), "README.pdf")
    }
}
