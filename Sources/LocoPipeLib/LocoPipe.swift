import ArgumentParser
import Foundation



enum Constants {
    static let tab: String = "\\t"
    static let languageFolderExtension = "lproj"
}

public struct LocoPipe: ParsableCommand {
    
    public static var configuration = CommandConfiguration(
        commandName: "locopipe",
        abstract: "LocoPipe is a simple tool that you can use to integrate into a simple Localization pipeline.  It converts Tab-separated tables (.TSV spreadsheet exports) into Localizable.strings files for use in your Apple projects.",
        usage: "locopipe Localizable -i ./someFile.tsv -o ../../Resources/Localization",
        discussion: "Please see README.md for more information.",
        version: "0.0.1",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil
    )
    
    
    
    @Argument(help: "The of the output .strings file(s)")
    public var name: String
    
    @Option(name: .shortAndLong, help: "The path to the input file.")
    public var input: String?
    
    @Option(name: .shortAndLong, help: "The path to the output folder.")
    public var output: String?
    
    @Flag(name: .long, help: "Otherwise known as a 'verbose' flag, it will print more information as it parses.")
    public var showDetails = false
    
    @Flag(name: .long, help: "Will take a .strings input folder and generate a .tsv file.")
    public var inverse = false
    
    @Flag(name: .shortAndLong, help: "Will output more debugging info as to what it's doing under the hood.")
    public var verbose = false
    
    @Option(name: .shortAndLong, help: "The language code that should be treated as the reference (for comments)")
    public var referenceLanguageCode: String?
    
    @Option(name: .shortAndLong, help: "Some applications that you want to import a TSV into, have trouble interpreting the tab character.  Override with your own type here.")
    public var delimiter: String?
    
    public init() {
        
    }
    
    public mutating func run() throws {
        
        if self.inverse {
            
            
            // parse the strings to TSV
            ConsoleIO.logDebug("Parsing Localizable Strings to TSV")
            let configuration: TSVFileGenerator.Configuration = try validateArguments()
            let parser = TSVFileGenerator(configuration)
            try parser.parseAndGenerateOutput()
            
        } else {
            // parse the TSV to strings
            ConsoleIO.logDebug("Parsing TSV File to Strings")
            let configuration: TSVFileParser.Configuration = try validateArguments()
            let parser = TSVFileParser(configuration)
            try parser.parseAndGenerateOutput()
        }
        
        
        ConsoleIO.logDebug("Generated Localization Files Successfully")
        //throw ExitCode.success
    }
    
    // MARK: - TSV Parsing
    
    func validateArguments() throws -> TSVFileParser.Configuration {
        
        guard let inputArg = self.input else {
            throw ValidationError("You need to provide an input argument or else this tool won't work!")
        }
        
        guard let outputArg = self.output else {
            throw ValidationError("You need to provide an output argument or else this tool won't work!")
        }
        
        let fm = FileManager.default
        
        // now determine if there is a file at that path
        var relativeDirectoryURL = inputArg.hasPrefix(".") ? URL(filePath: fm.currentDirectoryPath) : nil
        let inputURL = URL(filePath: inputArg, directoryHint: .notDirectory, relativeTo: relativeDirectoryURL)
        
        guard fm.fileExists(atPath: inputURL.path()) else {
            throw ValidationError("No file was found at \(inputArg)!")
        }
        
        relativeDirectoryURL = outputArg.hasPrefix(".") ? URL(filePath: fm.currentDirectoryPath) : nil
        let outputFolderURL = URL(filePath: outputArg, directoryHint: .isDirectory, relativeTo: relativeDirectoryURL)
        var isDir : ObjCBool = false
        if fm.fileExists(atPath: outputFolderURL.path(), isDirectory: &isDir) {
            if !isDir.boolValue {
                // file exists and is not a directory
                // invalid output path
                throw ValidationError("The provided output path is not a directory but needs to be!")
            }
        } else {
            try fm.createDirectory(at: outputFolderURL, withIntermediateDirectories: true)
        }
        
        
        return .init(name: self.name, inputFile: inputURL, outputFolder: outputFolderURL, isVerbose: self.verbose)
    }
    
    // MARK: - TSV Generating
    
    func validateArguments() throws -> TSVFileGenerator.Configuration {
        
        guard let inputArg = self.input else {
            throw ValidationError("You need to provide an input argument or else this tool won't work!")
        }
        
        guard let outputArg = self.output else {
            throw ValidationError("You need to provide an output argument or else this tool won't work!")
        }
        
        guard let referenceLanguageCode = self.referenceLanguageCode else {
            throw ValidationError("You need to provide a language code of the strings folder that will be treated as the reference language.")
        }
        
        let delimiter = self.delimiter ?? Constants.tab
        
        let fm = FileManager.default
        
        if self.verbose {
            ConsoleIO.logDebug("Current Working Directory: \(fm.currentDirectoryPath)")
        }
        
        
        // now determine if there is a file at that path
        var relativeDirectoryURL = outputArg.hasPrefix(".") ? URL(filePath: fm.currentDirectoryPath) : nil
        let outputFileURL = URL(filePath: outputArg, directoryHint: .notDirectory, relativeTo: relativeDirectoryURL)
        let outputFolderURL = outputFileURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: outputFolderURL.path()) {
            do {
                try fm.createDirectory(at: outputFolderURL, withIntermediateDirectories: true)
            } catch let e {
                if self.verbose {
                    ConsoleIO.logError("Failed creating directory: \(String.init(describing: e))")   
                }
                throw e
            }
        }
        
        relativeDirectoryURL = inputArg.hasPrefix(".") ? URL(filePath: fm.currentDirectoryPath) : nil
        let inputFolderURL = URL(filePath: inputArg, directoryHint: .isDirectory, relativeTo: relativeDirectoryURL)
        var isDir : ObjCBool = false
        if fm.fileExists(atPath: inputFolderURL.path(), isDirectory: &isDir) {
            if !isDir.boolValue {
                // file exists and is not a directory
                // invalid output path
                throw ValidationError("The provided output path is not a directory but needs to be!")
            }
        } else {
            throw ValidationError("The provided input path could not be found!")
        }
        
        do {
            let directoryContents = try fm.contentsOfDirectory(
                at: inputFolderURL,
                includingPropertiesForKeys: nil,
                options: [.skipsSubdirectoryDescendants]
            )
            
            var containsLprojFolder = false
            var containsReferenceLanguage = false
            for pathName in directoryContents {
                if pathName.lastPathComponent.contains(referenceLanguageCode) {
                    containsReferenceLanguage = true
                }
                if pathName.lastPathComponent.contains(Constants.languageFolderExtension) {
                    containsLprojFolder = true
                }
            }
            
            guard containsReferenceLanguage else {
                throw ValidationError("The input folder provided does not contain the specified reference language!")
            }
            
            guard containsLprojFolder else {
                throw ValidationError("The input folder provided does not contain any Localizable content folder (i.e. .lproj folder)")
            }
            
            return .init(
                name: self.name,
                inputFolder: inputFolderURL,
                outputFile: outputFileURL,
                referenceLanguageCode: referenceLanguageCode,
                delimiter: delimiter,
                isVerbose: self.verbose
            )

        } catch let e {
            if self.verbose {
                ConsoleIO.logError("Failed listing directory contents: \(e)")
            }
            throw e
        }
    }
}
