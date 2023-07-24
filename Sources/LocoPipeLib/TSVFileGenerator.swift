import Foundation

public struct TSVFileGenerator {
    
    public typealias LocalizationEntry = (key: String, value: String, comments: String)

    
    public struct Configuration {
        let name: String // name of the 'strings' file in the input folders
        let inputFolder: URL
        let outputFile: URL
        let referenceLanguageCode: String
    }
    
    public enum ParserError: Error, LocalizedError {
        case noContent
        case unexpectedFormat
        case internalError(details: String)
        
        public var errorDescription: String? {
            switch self {
            case .noContent:
                return "There was no content provided in the contentURL provided."
            case .unexpectedFormat:
                return "The provided .tsv sheet was not in the expected format.  There should be Columns [Comments, iOS Key], then language codes for each language you want to support."
            case .internalError(let details):
                return "An internal error occurred: \(details)"
            }
        }
    }
    
    let configuration: Configuration
    
    public init(_ configuration: Configuration) {
        self.configuration = configuration
    }
    
    public func parseAndGenerateOutput() throws {
        
        /// the key is the language code, the value is a dictionary where the key is they key to the localizationEntry which is also the value
        var parsedLanguages: [String: [String: LocalizationEntry]] = [:]
        
        do {
            let fm = FileManager.default
            let folderContents = try fm.contentsOfDirectory(at: configuration.inputFolder, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
            
            
            
            for folderName in folderContents where folderName.lastPathComponent.contains(Constants.languageFolderExtension) {
                let languageCode = (folderName.lastPathComponent as NSString).replacingOccurrences(of: ".\(Constants.languageFolderExtension)", with: "")
                
                var fileToParse: URL?
                let languageFolder = try fm.contentsOfDirectory(at: folderName, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
                for file in languageFolder {
                    if file.lastPathComponent.contains(".strings") {
                        fileToParse = file
                        break
                    }
                }
                guard let fileToParse = fileToParse else {
                    throw ParserError.noContent
                }
                
                if let parsedContent = try? parse(languageCode, from: fileToParse) {
                    parsedLanguages[languageCode] = parsedContent
                }
            }
            
            try generateTSVFile(from: parsedLanguages)
            
            
        } catch let e {
            print("Caught an error: \(String(describing: e))")
            throw e
        }
    }
    
    
    func parse(_ languageCode: String, from fileToParse: URL) throws -> [String: LocalizationEntry] {
        let stringsFile = try String(contentsOf: fileToParse)
        
        var currentComment: String?
        var currentKey: String?
        var currentValue: String?
        
        let lines = stringsFile.components(separatedBy: .newlines)
        
        var entries: [String: LocalizationEntry] = [:]
        
        for line in lines {
            // https://www.hackingwithswift.com/example-code/strings/how-to-trim-whitespace-in-a-string
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            if trimmed.hasPrefix("/*"), trimmed.hasSuffix("*/") {
                // is comment
                currentComment = extractComment(from: trimmed)
            } else if trimmed.hasPrefix("\"") {
                // is a key-value pair
                if let kvPair = extractPair(from: trimmed) {
                    currentKey = kvPair.key
                    currentValue = kvPair.value
                }
            }
            
            if let key = currentKey, let value = currentValue {
                entries[key] = (key: key, value: value, comments: currentComment ?? "(No Comment)")
                currentKey = nil
                currentValue = nil
                currentComment = nil
            }
        }
        return entries
    }
    
    func extractComment(from string: String) -> String? {
        return string
            .replacingOccurrences(of: "/*", with: "")
            .replacingOccurrences(of: "*/", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func extractPair(from string: String) -> (key: String, value: String)? {
        let split = string.components(separatedBy: "\" = \"")
        guard var key = split.first, var value = split.last else {
            return nil
        }
        
        if key.hasPrefix("\"") {
            key.removeFirst()
        }
        if value.hasSuffix("\";") {
            value = value.replacingOccurrences(of: "\";", with: "")
        } else {
            print("Value likely had a formatting problem!")
        }
        return (key: key, value: value)
    }
    
    func generateTSVFile(from parsedContent: [String: [String: LocalizationEntry]]) throws {
        
        let otherLanguageCodes = Array<String>(parsedContent.keys)
            .filter( { $0 != self.configuration.referenceLanguageCode })
            .sorted(by: <)
        
        guard let referenceLanguage = parsedContent[self.configuration.referenceLanguageCode] else {
            throw ParserError.internalError(details: "Did not expect there to be no reference language content at this point.")
        }
        
        var header = "Comments\(Constants.tab)iOS Key\(Constants.tab)\(self.configuration.referenceLanguageCode)"
        for otherLanguageCode in otherLanguageCodes {
            header += "\(Constants.tab)\(otherLanguageCode)"
        }
        var output = header + "\n"
        
        let contentKeys = Array<String>(referenceLanguage.keys).sorted(by: <)
        for key in contentKeys {
            guard let referenceContent = referenceLanguage[key] else {
                continue
            }
            var entry = "\(referenceContent.comments)\(Constants.tab)\(referenceContent.key)\(Constants.tab)\(referenceContent.value)"
            
            for otherLanguageCode in otherLanguageCodes {
                if let otherLanguage = parsedContent[otherLanguageCode], let languageContent = otherLanguage[key] {
                    entry += "\(Constants.tab)\(languageContent.value)"
                } else {
                    entry += "\(Constants.tab)\(referenceContent.value)"
                }
            }
            
            output += "\(entry)\n"
        }
        
        let fileDestination = self.configuration.outputFile
        try output.write(to: fileDestination, atomically: true, encoding: .utf8)
    }
}
