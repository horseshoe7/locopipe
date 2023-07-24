import Foundation

public typealias LocalizationEntry = (key: String, value: String, comments: String)

public final class TSVFileParser {
    
    public enum ParserError: Error, LocalizedError {
        case noContent
        case unexpectedFormat
        case unsupportedOutputFormat
        case internalError(details: String)
        
        public var errorDescription: String? {
            switch self {
            case .noContent:
                return "There was no content provided in the contentURL provided."
            case .unexpectedFormat:
                return "The provided .tsv sheet was not in the expected format.  There should be Columns [Comments, iOS Key], then language codes for each language you want to support."
            case .unsupportedOutputFormat:
                return "Currently this tool only supports output to Localizable.strings type iOS / OSX Localization format."
            case .internalError(let details):
                return "An internal error occurred: \(details)"
            }
        }
    }

    let configuration: LocoPipe.Configuration
    
    public init(_ configuration: LocoPipe.Configuration) {
        self.configuration = configuration
    }
    
    public func parseAndGenerateOutput() throws {
        
        do {
            let contents = try String(contentsOf: configuration.inputFile)
            print("Opened File:\n\(contents)")
            try parse(contents)
            
        } catch let e {
            print("Caught an error: \(String(describing: e))")
            throw e
        }
    }
}

extension TSVFileParser {
    
    var tab: String {
        return Self.tab
    }
    
    func parse(_ contents: String) throws {
        
        let results = try parseIntoDataStructure(contents)
        try export(results)
    }
    
    func parseIntoDataStructure(_ contents: String) throws -> [String: [LocalizationEntry]] {
        
        // need a data structure here
        let rows = contents.components(separatedBy: CharacterSet.newlines)
        
        var languageColumns: [String: Int] = [:] // key is the language code
        var entriesByLanguage: [String: [LocalizationEntry]] = [:]  // key is the language code
        
        guard let firstRow = rows.first else {
            throw ParserError.noContent
        }
        
        // the document should have comments, iOS Key, Android Key, then at least one language
        let columnHeaders = firstRow.components(separatedBy: tab)
        guard columnHeaders.count >= numberOfNonLanguageColumns + 1 else {
            throw ParserError.unexpectedFormat
        }
        
        for i in numberOfNonLanguageColumns..<columnHeaders.count {
            let languageCode = columnHeaders[i]
            languageColumns[languageCode] = i
        }
        
        let commentsColumn: Int = 0
        let keyColumn: Int = 1 // Corresponds to the iOS Key column
        
        for i in 1..<rows.count {
            let row = rows[i]
            
            // sometimes the code that created the rows creates an empty row due to /r/n
            if row.isEmpty { continue }
            
            // need a regex that will parse these as expected
            let columns = TSVFileParser.getColumnValues(from: row)
            guard columns.count == numberOfNonLanguageColumns + languageColumns.count else {
                throw ParserError.internalError(details: "The Regex Parser is not working as expected (yet).  There should be 2 columns + number of detected languages in the .tsv sheet")
            }
            
            for languageCode in languageColumns.keys {
                
                let languageColumn = languageColumns[languageCode]!
                let entry: LocalizationEntry = (key: columns[keyColumn], value: columns[languageColumn], comments: columns[commentsColumn])
                
                var existingEntries: [LocalizationEntry] = entriesByLanguage[languageCode] ?? []
                existingEntries.append(entry)
                entriesByLanguage[languageCode] = existingEntries
            }
        }
        
        return entriesByLanguage
    }
    
    func export(_ results: [String: [LocalizationEntry]]) throws {
        
        do {
        
            let fm = FileManager.default
            
            // get output folder, create if necessary
            // for each language, create a <languageCode>.lproj folder if it doesn't exist
            for languageCode in results.keys {
                let folderName = "/\(languageCode).lproj"
                let outputFolder = self.configuration.outputFolder.appendingPathComponent(folderName)
                
                if !fm.fileExists(atPath: outputFolder.path, isDirectory: nil) {
                    try fm.createDirectory(at: outputFolder, withIntermediateDirectories: true, attributes: nil)
                }
                
                let outputFileURL = outputFolder.appendingPathComponent(filenameOfStringsFile)
                
                // generate file at path, using [LocalizationEntry]
                if let entries = results[languageCode] {
                    try generateOutput(at: outputFileURL, with: entries)
                }
            }
            
        } catch let error {
            // could repackage it here.
            throw error
        }
    }
    
    var filenameOfStringsFile: String {
        if self.configuration.name.contains(".strings") { return self.configuration.name }
        return "\(self.configuration.name).strings"
    }
    
    var numberOfNonLanguageColumns: Int {
        return 2 // could be 3 in the future (Android support)
    }
    
    static let tab: String = "\\t"
    
    static func getColumnValues(from tsvText: String) -> [String] {
        
        return tsvText.components(separatedBy: tab)
    }
    
    // will only throw if there's a write error
    func generateOutput(at fileDestination: URL, with entries: [LocalizationEntry]) throws {
        
        var output = ""
        
        for entry in entries {
            output += "/* \(entry.comments) */\n"
            output += "\"\(entry.key)\" = \"\(entry.value)\";\n"
            output += "\n"
        }
        
        try output.write(to: fileDestination, atomically: true, encoding: .utf8)
    }
}
