import ArgumentParser
import Foundation

@available(macOS 13.0, *)
@main
struct MarkdownEPUBConverter: ParsableCommand {

    @Argument(
        help: "The path to the EPUB file",
        transform: URL.init(fileURLWithPath:)
    )
    var epubURL: URL

    @Argument(
        help: """
              The path to result of conversion. In that path a directory will be \
              created with the same name as the Epub without the .epub extension
              """,
        transform: URL.init(fileURLWithPath:)
    )
    var destination: URL?

    private var resultDirectory: URL!

    mutating func validate() throws {
        let filemanager = FileManager.default

        guard filemanager.fileExists(atPath: epubURL.path) else {
            throw ValidationError("File does not exist at \(epubURL.path)")
        }

        let filenameWithoutExtension = epubURL.deletingPathExtension().lastPathComponent

        if let destination {
            guard filemanager.fileExists(atPath: destination.path) else {
                throw ValidationError("""
                The path to result directory: \(destination.path) does not exist.
                """)
            }
            resultDirectory = destination.appending(component: filenameWithoutExtension)
        } else {
            resultDirectory = epubURL.deletingLastPathComponent().appending(component: filenameWithoutExtension)
        }
    }

    mutating func run() throws {
        let filemanager = FileManager.default

        if filemanager.directoryExists(at: resultDirectory) {
            let prompt = """
            ⚠️ The target directory already exists, do you want to delete it?:
            """
            if confirm(prompt: prompt) {
                try filemanager.removeItem(atPath: resultDirectory.path)
            } else {
                print("The target directory has not been modified")
                return
            }
        }

        let imagesDirectory = resultDirectory.appending(path: "images")
        try filemanager.createDirectory(atPath: imagesDirectory.path, withIntermediateDirectories: true)

        let extractor = try EPUBExtractor(url: epubURL)
        try extractor.copyImages(to: imagesDirectory)
        try extractor.extract(in: resultDirectory)
    }
}

@available(macOS 13.0, *)
private extension MarkdownEPUBConverter {
    private func confirm(prompt: String) -> Bool {
        print("\(prompt) [y/N]: ", terminator: "")

        guard
            let input = readLine()?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
            !input.isEmpty
        else {
            return false
        }

        return input == "y" || input == "yes"
    }
}
