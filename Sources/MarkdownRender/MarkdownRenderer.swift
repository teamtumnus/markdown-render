import Foundation

enum MarkdownRenderer {
    static func render(markdown: String, fileURL: URL?) throws -> String {
        var parser = Parser(markdown: markdown)
        let title = fileURL?.lastPathComponent ?? "MarkdownRender"
        return htmlDocument(title: title, body: parser.render())
    }

    static func placeholderHTML() -> String {
        htmlDocument(
            title: "MarkdownRender",
            body: """
            <section class="empty-state">
              <h1>MarkdownRender</h1>
              <p>Open a Markdown file to preview it.</p>
              <p>Use Export PDF when the preview is ready.</p>
            </section>
            """
        )
    }

    static func errorHTML(title: String, message: String) -> String {
        htmlDocument(
            title: title,
            body: """
            <section class="error-state">
              <h1>\(escapeText(title))</h1>
              <p>\(escapeText(message))</p>
            </section>
            """
        )
    }

    static func htmlDocument(title: String, body: String) -> String {
        """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(escapeText(title))</title>
          <style>
          :root {
            color-scheme: light;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
          }

          * {
            box-sizing: border-box;
          }

          body {
            margin: 0;
            background: #ffffff;
            color: #111827;
            font: 16px/1.6 -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
          }

          main {
            max-width: 900px;
            margin: 0 auto;
            padding: 32px 24px 48px;
          }

          h1, h2, h3, h4, h5, h6 {
            line-height: 1.2;
            margin: 1.5em 0 0.5em;
          }

          h1:first-child,
          h2:first-child,
          h3:first-child {
            margin-top: 0;
          }

          p, ul, ol, pre, blockquote, hr {
            margin: 0 0 1em;
          }

          ul, ol {
            padding-left: 1.5em;
          }

          li + li {
            margin-top: 0.25em;
          }

          code {
            font: 0.92em Menlo, Monaco, "SF Mono", monospace;
            background: #f3f4f6;
            border-radius: 6px;
            padding: 0.12em 0.35em;
          }

          pre {
            overflow-x: auto;
            background: #111827;
            color: #f9fafb;
            border-radius: 12px;
            padding: 14px 16px;
          }

          pre code {
            background: transparent;
            color: inherit;
            padding: 0;
          }

          blockquote {
            border-left: 4px solid #d1d5db;
            color: #374151;
            padding-left: 16px;
          }

          .admonition {
            margin: 0 0 1em;
            padding: 16px 18px;
            border-left: 4px solid #64748b;
            border-radius: 12px;
            background: #f8fafc;
          }

          .admonition-title {
            margin: 0 0 0.65em;
            font-weight: 700;
            line-height: 1.3;
            color: #0f172a;
          }

          .admonition > :last-child {
            margin-bottom: 0;
          }

          .admonition-note,
          .admonition-abstract,
          .admonition-info,
          .admonition-example {
            border-left-color: #2563eb;
            background: #eff6ff;
          }

          .admonition-tip,
          .admonition-success {
            border-left-color: #059669;
            background: #ecfdf5;
          }

          .admonition-important,
          .admonition-question {
            border-left-color: #7c3aed;
            background: #f5f3ff;
          }

          .admonition-warning,
          .admonition-caution {
            border-left-color: #d97706;
            background: #fff7ed;
          }

          .admonition-danger,
          .admonition-failure,
          .admonition-bug {
            border-left-color: #dc2626;
            background: #fef2f2;
          }

          .admonition-quote {
            border-left-color: #475569;
            background: #f8fafc;
          }

          a {
            color: #0f62fe;
            text-decoration: none;
          }

          a:hover {
            text-decoration: underline;
          }

          img {
            display: block;
            max-width: 100%;
            height: auto;
            margin: 1em 0;
            border-radius: 10px;
          }

          hr {
            border: 0;
            border-top: 1px solid #d1d5db;
          }

          .empty-state,
          .error-state {
            min-height: calc(100vh - 80px);
            display: flex;
            flex-direction: column;
            justify-content: center;
          }

          .error-state h1 {
            color: #b91c1c;
          }

          @page {
            margin: 18mm;
          }

          @media print {
            body {
              font-size: 12pt;
            }

            main {
              max-width: none;
              padding: 0;
            }

            a {
              color: inherit;
            }
          }
          </style>
        </head>
        <body>
          <main>
            \(body)
          </main>
        </body>
        </html>
        """
    }

    static func escapeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func escapeAttribute(_ text: String) -> String {
        escapeText(text)
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

private struct Parser {
    private let lines: [String]
    private var index = 0
    private var blocks: [String] = []
    private var paragraphLines: [String] = []
    private var currentListType: ListType?
    private var currentListItems: [String] = []

    init(markdown: String) {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    mutating func render() -> String {
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                flushList()
                index += 1
                continue
            }

            if let codeBlock = parseCodeBlock(startingAt: trimmed) {
                flushParagraph()
                flushList()
                blocks.append(codeBlock)
                continue
            }

            if let heading = parseHeading(from: trimmed) {
                flushParagraph()
                flushList()
                blocks.append(heading)
                index += 1
                continue
            }

            if let admonition = parseAdmonition(from: line, trimmed: trimmed) {
                flushParagraph()
                flushList()
                blocks.append(admonition)
                continue
            }

            if let quote = parseBlockquote(from: trimmed) {
                flushParagraph()
                flushList()
                blocks.append(quote)
                continue
            }

            if isHorizontalRule(trimmed) {
                flushParagraph()
                flushList()
                blocks.append("<hr>")
                index += 1
                continue
            }

            if let (type, item) = parseListItem(from: trimmed) {
                flushParagraph()
                appendListItem(type: type, item: item)
                index += 1
                continue
            }

            flushList()
            paragraphLines.append(trimmed)
            index += 1
        }

        flushParagraph()
        flushList()
        return blocks.joined(separator: "\n")
    }

    private mutating func parseAdmonition(from rawLine: String, trimmed line: String) -> String? {
        if let admonition = parseFencedAdmonition(from: line) {
            return admonition
        }

        if let admonition = parseQuotedAdmonition(from: rawLine, trimmed: line) {
            return admonition
        }

        return nil
    }

    private mutating func parseFencedAdmonition(from line: String) -> String? {
        guard line.hasPrefix("!!!") else {
            return nil
        }

        let marker = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
        guard let header = parseAdmonitionHeader(marker) else {
            return nil
        }

        index += 1

        var contentLines: [String] = []
        while index < lines.count {
            let nextLine = lines[index]

            if nextLine.trimmingCharacters(in: .whitespaces).isEmpty {
                contentLines.append("")
                index += 1
                continue
            }

            guard let strippedLine = stripAdmonitionIndentation(from: nextLine) else {
                break
            }

            contentLines.append(strippedLine)
            index += 1
        }

        return renderAdmonition(type: header.type, title: header.title, markdown: contentLines.joined(separator: "\n"))
    }

    private mutating func parseQuotedAdmonition(from rawLine: String, trimmed line: String) -> String? {
        guard line.hasPrefix(">") else {
            return nil
        }

        let firstContent = stripBlockquotePrefix(from: rawLine)
        guard let header = parseGitHubCalloutHeader(firstContent.trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        index += 1

        var contentLines: [String] = []
        while index < lines.count {
            let nextLine = lines[index]
            let nextTrimmed = nextLine.trimmingCharacters(in: .whitespaces)
            guard nextTrimmed.hasPrefix(">") else {
                break
            }

            contentLines.append(stripBlockquotePrefix(from: nextLine))
            index += 1
        }

        return renderAdmonition(type: header.type, title: header.title, markdown: contentLines.joined(separator: "\n"))
    }

    private mutating func parseCodeBlock(startingAt line: String) -> String? {
        guard line.hasPrefix("```") else {
            return nil
        }

        let language = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
        index += 1

        var codeLines: [String] = []
        while index < lines.count {
            let nextLine = lines[index]
            if nextLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                index += 1
                break
            }

            codeLines.append(nextLine)
            index += 1
        }

        let escapedCode = MarkdownRenderer.escapeText(codeLines.joined(separator: "\n"))
        let languageClass = language.isEmpty ? "" : " class=\"language-\(MarkdownRenderer.escapeAttribute(language))\""
        return "<pre><code\(languageClass)>\(escapedCode)</code></pre>"
    }

    private func parseHeading(from line: String) -> String? {
        let level = line.prefix { $0 == "#" }.count
        guard (1...6).contains(level) else {
            return nil
        }

        let contentStart = line.index(line.startIndex, offsetBy: level)
        let content = line[contentStart...].trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else {
            return nil
        }

        return "<h\(level)>\(renderInline(content))</h\(level)>"
    }

    private mutating func parseBlockquote(from line: String) -> String? {
        guard line.hasPrefix(">") else {
            return nil
        }

        var quoteLines: [String] = []
        while index < lines.count {
            let nextLine = lines[index]
            let nextTrimmed = nextLine.trimmingCharacters(in: .whitespaces)
            guard nextTrimmed.hasPrefix(">") else {
                break
            }

            quoteLines.append(stripBlockquotePrefix(from: nextLine))
            index += 1
        }

        var nested = Parser(markdown: quoteLines.joined(separator: "\n"))
        return "<blockquote>\(nested.render())</blockquote>"
    }

    private func isHorizontalRule(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        return compact == "---" || compact == "***"
    }

    private func parseListItem(from line: String) -> (ListType, String)? {
        if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
            return (.unordered, String(line.dropFirst(2)))
        }

        var digits = ""
        var iterator = line.makeIterator()
        while let char = iterator.next(), char.isNumber {
            digits.append(char)
        }

        guard !digits.isEmpty else {
            return nil
        }

        let prefix = "\(digits). "
        guard line.hasPrefix(prefix) else {
            return nil
        }

        return (.ordered, String(line.dropFirst(prefix.count)))
    }

    private mutating func appendListItem(type: ListType, item: String) {
        if currentListType != type {
            flushList()
            currentListType = type
        }

        currentListItems.append(item)
    }

    private mutating func flushParagraph() {
        guard !paragraphLines.isEmpty else {
            return
        }

        let content = paragraphLines.joined(separator: " ")
        blocks.append("<p>\(renderInline(content))</p>")
        paragraphLines.removeAll(keepingCapacity: true)
    }

    private mutating func flushList() {
        guard let currentListType, !currentListItems.isEmpty else {
            currentListType = nil
            return
        }

        let tag = currentListType == .ordered ? "ol" : "ul"
        let items = currentListItems.map { "<li>\(renderInline($0))</li>" }.joined()
        blocks.append("<\(tag)>\(items)</\(tag)>")
        currentListItems.removeAll(keepingCapacity: true)
        self.currentListType = nil
    }

    private func parseAdmonitionHeader(_ text: String) -> (type: String, title: String)? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return nil
        }

        let typeEnd = trimmed.firstIndex(where: \.isWhitespace) ?? trimmed.endIndex
        let rawType = String(trimmed[..<typeEnd])
        let remainder = String(trimmed[typeEnd...]).trimmingCharacters(in: .whitespaces)

        let normalizedType = normalizeAdmonitionType(rawType)
        let title = parseQuotedTitle(from: remainder) ?? defaultAdmonitionTitle(for: normalizedType)
        return (normalizedType, title)
    }

    private func parseGitHubCalloutHeader(_ text: String) -> (type: String, title: String?)? {
        guard text.hasPrefix("[!") else {
            return nil
        }

        guard let closingBracket = text.firstIndex(of: "]") else {
            return nil
        }

        let typeStart = text.index(text.startIndex, offsetBy: 2)
        guard typeStart < closingBracket else {
            return nil
        }

        let rawType = String(text[typeStart..<closingBracket])
        let normalizedType = normalizeAdmonitionType(rawType)

        let remainderStart = text.index(after: closingBracket)
        let remainder = remainderStart < text.endIndex
            ? String(text[remainderStart...]).trimmingCharacters(in: .whitespaces)
            : ""
        let title = remainder.isEmpty ? nil : remainder

        return (normalizedType, title)
    }

    private func normalizeAdmonitionType(_ rawType: String) -> String {
        let trimmed = rawType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let scalars = trimmed.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == "-" }
        let normalized = String(String.UnicodeScalarView(scalars))
        return normalized.isEmpty ? "note" : normalized
    }

    private func defaultAdmonitionTitle(for type: String) -> String {
        type
            .split(separator: "-")
            .map { segment in
                let word = String(segment)
                guard let first = word.first else {
                    return word
                }

                return first.uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    private func parseQuotedTitle(from text: String) -> String? {
        guard text.hasPrefix("\""), text.count >= 2 else {
            return nil
        }

        let titleStart = text.index(after: text.startIndex)
        guard let titleEnd = text[titleStart...].firstIndex(of: "\"") else {
            return nil
        }

        return String(text[titleStart..<titleEnd])
    }

    private func stripAdmonitionIndentation(from line: String) -> String? {
        if line.hasPrefix("\t") {
            return String(line.dropFirst())
        }

        guard line.hasPrefix("    ") else {
            return nil
        }

        return String(line.dropFirst(4))
    }

    private func stripBlockquotePrefix(from line: String) -> String {
        guard let markerIndex = line.firstIndex(of: ">") else {
            return line.trimmingCharacters(in: .whitespaces)
        }

        let afterMarker = line.index(after: markerIndex)
        var content = String(line[afterMarker...])
        if content.first == " " {
            content.removeFirst()
        }
        return content
    }

    private func renderAdmonition(type: String, title: String?, markdown: String) -> String {
        var nested = Parser(markdown: markdown)
        let renderedBody = nested.render()
        let resolvedTitle = title ?? defaultAdmonitionTitle(for: type)
        let titleHTML = "<p class=\"admonition-title\">\(renderInline(resolvedTitle))</p>"
        return "<section class=\"admonition admonition-\(MarkdownRenderer.escapeAttribute(type))\">\(titleHTML)\(renderedBody)</section>"
    }

    private func renderInline(_ text: String) -> String {
        var output = ""
        var index = text.startIndex

        while index < text.endIndex {
            if text[index] == "\\" {
                let nextIndex = text.index(after: index)
                if nextIndex < text.endIndex {
                    output += MarkdownRenderer.escapeText(String(text[nextIndex]))
                    index = text.index(after: nextIndex)
                } else {
                    index = nextIndex
                }
                continue
            }

            if text[index] == "`", let parsed = consumeDelimited("`", in: text, from: index) {
                output += "<code>\(MarkdownRenderer.escapeText(parsed.content))</code>"
                index = parsed.nextIndex
                continue
            }

            if let parsed = consumeImage(in: text, from: index) {
                output += parsed.html
                index = parsed.nextIndex
                continue
            }

            if let parsed = consumeLink(in: text, from: index) {
                output += parsed.html
                index = parsed.nextIndex
                continue
            }

            if let parsed = consumeDelimited("**", in: text, from: index) {
                output += "<strong>\(renderInline(parsed.content))</strong>"
                index = parsed.nextIndex
                continue
            }

            if let parsed = consumeDelimited("__", in: text, from: index) {
                output += "<strong>\(renderInline(parsed.content))</strong>"
                index = parsed.nextIndex
                continue
            }

            if let parsed = consumeDelimited("*", in: text, from: index) {
                output += "<em>\(renderInline(parsed.content))</em>"
                index = parsed.nextIndex
                continue
            }

            if let parsed = consumeDelimited("_", in: text, from: index) {
                output += "<em>\(renderInline(parsed.content))</em>"
                index = parsed.nextIndex
                continue
            }

            output += MarkdownRenderer.escapeText(String(text[index]))
            index = text.index(after: index)
        }

        return output
    }

    private func consumeDelimited(
        _ delimiter: String,
        in text: String,
        from start: String.Index
    ) -> (content: String, nextIndex: String.Index)? {
        guard text[start...].hasPrefix(delimiter) else {
            return nil
        }

        let contentStart = text.index(start, offsetBy: delimiter.count)
        guard contentStart < text.endIndex else {
            return nil
        }

        guard let closingRange = text.range(of: delimiter, range: contentStart..<text.endIndex) else {
            return nil
        }

        let content = String(text[contentStart..<closingRange.lowerBound])
        guard !content.isEmpty else {
            return nil
        }

        return (content, closingRange.upperBound)
    }

    private func consumeImage(
        in text: String,
        from start: String.Index
    ) -> (html: String, nextIndex: String.Index)? {
        guard text[start...].hasPrefix("![") else {
            return nil
        }

        guard let parsed = consumeBracketAndDestination(in: text, from: start, labelOffset: 2) else {
            return nil
        }

        let alt = MarkdownRenderer.escapeAttribute(parsed.label)
        let source = MarkdownRenderer.escapeAttribute(parsed.destination)
        return ("<img src=\"\(source)\" alt=\"\(alt)\">", parsed.nextIndex)
    }

    private func consumeLink(
        in text: String,
        from start: String.Index
    ) -> (html: String, nextIndex: String.Index)? {
        guard text[start] == "[" else {
            return nil
        }

        guard let parsed = consumeBracketAndDestination(in: text, from: start, labelOffset: 1) else {
            return nil
        }

        let href = MarkdownRenderer.escapeAttribute(parsed.destination)
        return ("<a href=\"\(href)\">\(renderInline(parsed.label))</a>", parsed.nextIndex)
    }

    private func consumeBracketAndDestination(
        in text: String,
        from start: String.Index,
        labelOffset: Int
    ) -> (label: String, destination: String, nextIndex: String.Index)? {
        let labelStart = text.index(start, offsetBy: labelOffset)
        guard labelStart < text.endIndex else {
            return nil
        }

        guard let labelEnd = text[labelStart...].firstIndex(of: "]") else {
            return nil
        }

        let openParen = text.index(after: labelEnd)
        guard openParen < text.endIndex, text[openParen] == "(" else {
            return nil
        }

        let destinationStart = text.index(after: openParen)
        guard destinationStart < text.endIndex else {
            return nil
        }

        guard let destinationEnd = text[destinationStart...].firstIndex(of: ")") else {
            return nil
        }

        let label = String(text[labelStart..<labelEnd])
        let rawDestination = String(text[destinationStart..<destinationEnd])
        guard let destination = normalizeDestination(rawDestination) else {
            return nil
        }

        return (label, destination, text.index(after: destinationEnd))
    }

    private func normalizeDestination(_ rawDestination: String) -> String? {
        let trimmed = rawDestination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if trimmed.hasPrefix("<"), trimmed.hasSuffix(">"), trimmed.count > 2 {
            return String(trimmed.dropFirst().dropLast())
        }

        if let spaceIndex = trimmed.firstIndex(where: \.isWhitespace) {
            return String(trimmed[..<spaceIndex])
        }

        return trimmed
    }

    private enum ListType {
        case ordered
        case unordered
    }
}
