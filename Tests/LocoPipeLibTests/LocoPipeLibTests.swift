import XCTest
@testable import LocoPipeLib

final class LocoPipeTests: XCTestCase {
    
    func testRegexWorksOnABasicLevel() {
        
        let lineOne = "Purpose / Comments\\tiOS Key\\ten"
        let results = TSVFileParser.getColumnValues(from: lineOne, delimiter: "\\t")
        XCTAssertTrue(results.count == 3, "Expected 3 Results")
    }
    
    func testRegexWorksForActualCommasAndNotJustDelimitedCommas() {
        let lineTwo = "Testing\\tTesting.MyKey.Name\\tThis is a text string I am localizing. Wondering, can I have commas in a tsv?"
		let results = TSVFileParser.getColumnValues(from: lineTwo, delimiter: "\\t")
        XCTAssertTrue(results.count == 3, "Expected 3 Results")
    }
    
    func testParserEndToEndWithBasicFile() throws {
        guard let testFileURL = Bundle.module.url(forResource: "Resources/TestFile.tsv", withExtension: nil) else {
            return XCTFail("Could not open resource for test")
        }
        
        var locopipe = LocoPipe()
        
        // you have to provide all arguments that are required to work.  This isn't the case when running from the command line.
        locopipe.name = "Localizable"
        locopipe.input = testFileURL.path()
        locopipe.output = NSTemporaryDirectory()
        locopipe.inverse = false
        locopipe.verbose = true
		locopipe.delimiter = nil

        
        try locopipe.run()
        
        print("End to end test.  Output at: \(String(describing: locopipe.output))")
    }
    
    func testGeneratorEndToEndWithBasicFile() throws {
        guard
            let deStrings = Bundle.module.url(forResource: "Resources/de.strings", withExtension: nil),
            let enStrings = Bundle.module.url(forResource: "Resources/en.strings", withExtension: nil)
        else {
            return XCTFail("Could not open resource for test")
        }
        
        var locopipe = LocoPipe()
        
        // you have to provide all arguments that are required to work.  This isn't the case when running from the command line.
        locopipe.name = "Localizable"
        locopipe.input = placeTestFilesIntoTempFolder([deStrings, enStrings])
        locopipe.output = "\(locopipe.input!)/Output.tsv"
        locopipe.inverse = true
        locopipe.referenceLanguageCode = "en"
        locopipe.verbose = true
        locopipe.delimiter = nil
        
        try locopipe.run()
        
        print("End to end test.  Output at: \(String(describing: locopipe.output))")
    }
    
    private func placeTestFilesIntoTempFolder(_ files: [URL]) -> String {
        let rootURL = URL(filePath: NSTemporaryDirectory(), directoryHint: .isDirectory).appending(path: "LocoPipeLibTests")
        
        let fm = FileManager.default
        
        for file in files {
            let languageCode = file.deletingPathExtension().lastPathComponent
            let folderName = "\(languageCode).\(Constants.languageFolderExtension)"
            
            do {
                let fileDestinationFolder = rootURL.appending(path: folderName, directoryHint: .isDirectory)
                if !fm.fileExists(atPath: fileDestinationFolder.path()) {
                    try fm.createDirectory(at: fileDestinationFolder, withIntermediateDirectories: true)
                }
                let fileDestination = fileDestinationFolder.appending(path: "Localizable.strings", directoryHint: .notDirectory)
                
                if fm.fileExists(atPath: fileDestination.path()) {
                    try fm.removeItem(at: fileDestination)
                }

                try fm.copyItem(at: file, to: fileDestination)
                
            } catch {
                print("Error setting up test: \(error)")
            }
        }
        
        return rootURL.path()
    }
}
