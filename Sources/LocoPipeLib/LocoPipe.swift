import ArgumentParser
import Foundation


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
    
    public struct Configuration {
        let name: String
        let inputFile: URL
        let outputFolder: URL
    }
    
    @Argument(help: "The of the output .strings file(s)")
    public var name: String
    
    @Option(name: .shortAndLong, help: "The path to the input file.")
    public var input: String?
    
    @Option(name: .shortAndLong, help: "The path to the output folder.")
    public var output: String?
    
    @Flag(help: "Otherwise known as a 'verbose' flag, it will print more information as it parses.")
    public var showDetails = false
    
    
    public init() {
        
    }
//    public init(name: String, input: String? = nil, output: String? = nil, showDetails: Bool = false) {
//        self.name = name
//        self.input = input
//        self.output = output
//        self.showDetails = showDetails
//    }
    
    public mutating func run() throws {
        
        var input: String = ""
        var output: String = ""
        
        let configuration = try validateArguments(input: &input, output: &output)
        
        let parser = TSVFileParser(configuration)
        
        try parser.parseAndGenerateOutput()
        
        print("Generated Localization Files Successfully")
        //throw ExitCode.success
    }
    
    func validateArguments(input: inout String, output: inout String) throws -> LocoPipe.Configuration {
        
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
        
        
        return .init(name: self.name, inputFile: inputURL, outputFolder: outputFolderURL)
    }
}
