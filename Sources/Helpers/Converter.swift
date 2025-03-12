import SwiftSoup
import Foundation

struct ConverterResult {
    let title: String?
    let markdown: String
}

final class Converter {
    private let imagesPath: String
    private let fileManager = FileManager.default

    init(imagesPath: String) {
        self.imagesPath = imagesPath
    }

    func convertToMarkdown(html: String) throws -> ConverterResult? {
        let document = try SwiftSoup.parse(html)
        guard let body = document.body() else { return nil }
        let markdown = try parseElement(body)
        let title = try parseTitle(body)
        return ConverterResult(title: title, markdown: markdown)
    }

    private func parseTitle(_ element: Element) throws -> String? {
        guard let firstH1 = try? element.select("h1").first() else { return nil }
        return try? firstH1.text()
    }

    private func parseElement(_ element: Element) throws -> String {
        var markdown = ""

        for node in element.getChildNodes() {
            if let textNode = node as? TextNode {
                markdown.append(textNode.text())
            } else if let childElement = node as? Element {
                markdown.append(try parseTag(childElement))
            }
        }

        return deleteSpacesAtStartOfLines(string: markdown)
    }

    private func deleteSpacesAtStartOfLines(string: String) -> String {
        let pattern = #"(?m)^ {1}(?! )"# // #"(?m)^ "#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: string.utf16.count)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
    }

    private func parseTag(_ element: Element) throws -> String {
        switch element.tagName() {
        case "div": return try parseElement(element)
        case "h1": return "# " + (try parseElement(element)) + "\n\n"
        case "h2": return "## " + (try parseElement(element)) + "\n\n"
        case "h3": return "### " + (try parseElement(element)) + "\n\n"
        case "h4": return "#### " + (try parseElement(element)) + "\n\n"
        case "h5": return "##### " + (try parseElement(element)) + "\n\n"
        case "h6": return "###### " + (try parseElement(element)) + "\n\n"
        case "p": return (try parseElement(element)) + "\n\n"
        case "strong": return "**" + (try parseElement(element)) + "**"
        case "em": return "*" + (try parseElement(element)) + "*"
        case "ul": return try parseList(element, ordered: false)
        case "ol": return try parseList(element, ordered: true)
        case "li": return "- " + (try parseElement(element)) + "\n"
        case "a":
            let href = try element.attr("href")
            return "[" + (try parseElement(element)) + "](\(href))"
        case "code": return "`" + (try parseElement(element)) + "`"
        case "pre": return "\n```\n" + (try element.text()) + "\n```\n\n"
        case "blockquote": return "> " + (try parseElement(element)).replacingOccurrences(of: "\n", with: "\n> ") + "\n\n"
        case "br": return "\n"
        case "img":
            let src = try element.attr("src")
            let newSrc = processImageSrc(src)
            let alt = try element.attr("alt")
            return "![\(alt)](\(newSrc))\n\n"
        default: return try parseElement(element)
        }
    }

    private func parseList(_ element: Element, ordered: Bool) throws -> String {
        var markdown = "\n"
        let listItems = try element.select("li")
        for (index, li) in listItems.enumerated() {
            let prefix = ordered ? "\(index + 1). " : "- "
            markdown.append(prefix + (try parseElement(li)) + "\n")
        }
        return markdown + "\n"
    }

    private func processImageSrc(_ imageSrc: String) -> String {
        let url = URL(fileURLWithPath: imageSrc)
        return imagesPath + "/" + url.lastPathComponent
    }
}
