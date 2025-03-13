import Foundation
import ZIPFoundation

enum ExtractorError: Error {
    case extractingDocument
    case extractingMarkdow
    case writingMarkdow(String)
}

@available(macOS 13.0, *)
final class Extractor {
    let archive: Archive

    init(url: URL) throws {
        archive = try Archive(url: url, accessMode: .read, pathEncoding: nil)
    }

    func copyImages(to imagesDir: URL) throws {
        let images = archive.filter {
            let fileExtension = $0.path.lowercased().split(separator: ".").last ?? ""

            return fileExtension == "png"
                || fileExtension == "svg"
                || fileExtension == "jpg"
                || fileExtension == "jpeg"
                || fileExtension == "gif"
        }

        for image in images {
            guard let name = image.path.split(separator: "/").last else { continue }
            var imageData = Data()
            _ = try archive.extract(image, consumer: { imageData.append($0) })
            let url = imagesDir.appending(component: name)
            try imageData.write(to: url)
        }
    }

    func extract(in resultDir: URL, withImagesPath imagesPath: String) throws {
        let converter = Converter(imagesPath: imagesPath)
        let htmlEntries = archive
            .filter {
                $0.path.lowercased().hasSuffix(".xhtml") || $0.path.lowercased().hasSuffix(".html")
            }

        for entry in htmlEntries {
            let entryFilename = entry.filename
            let htmlString = try extractHtmlOfEntry(entry)

            guard
                let converterResult = try extractMarkdowOf(htmlString: htmlString, converter: converter)
            else {
                throw ExtractorError.extractingDocument
            }

            let filename = generateFilename(filename: entryFilename, title: converterResult.title)
            let markdown = converterResult.markdown
            try write(markdown: markdown, withName: filename, in: resultDir)
        }
    }

    private func generateFilename(filename: String, title: String?) -> String {
        guard let title else { return "\(filename).md" }
        let cleanedTitle = title.replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: " ", with: "_")
        return "\(cleanedTitle).md"
    }

    private func write(markdown: String, withName name: String, in resultDir: URL) throws {
        guard let data = markdown.data(using: .utf8) else { throw ExtractorError.writingMarkdow(name) }
        let url = resultDir.appending(path: name)
        do {
            try data.write(to: url)
        } catch {
            throw ExtractorError.writingMarkdow(name)
        }
    }

    private func extractHtmlOfEntry(_ entry: Entry) throws -> String {
        var htmlData = Data()
        _ = try archive.extract(entry, consumer: { htmlData.append($0) })
        let htmlString = String(decoding: htmlData, as: UTF8.self)
        guard !htmlString.isEmpty else { throw ExtractorError.extractingDocument }
        return htmlString
    }

    private func extractMarkdowOf(htmlString: String, converter: Converter) throws -> ConverterResult? {
        do {
            return try converter.convertToMarkdown(html: htmlString)
        } catch {
            throw ExtractorError.extractingDocument
        }
    }
}

extension Entry {
    var filename: String {
        URL(fileURLWithPath: path.lowercased()).deletingPathExtension().lastPathComponent
    }
}
