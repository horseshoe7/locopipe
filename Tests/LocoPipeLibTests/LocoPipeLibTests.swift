import XCTest
@testable import LocoPipeLib

final class LocoPipeTests: XCTestCase {
    
    func testRegexWorksOnABasicLevel() {
        
        let lineOne = "Purpose / Comments\\tiOS Key\\ten"
        let results = TSVFileParser.getColumnValues(from: lineOne)
        XCTAssertTrue(results.count == 3, "Expected 3 Results")
    }
    
    func testRegexWorksForActualCommasAndNotJustDelimitedCommas() {
        let lineTwo = "Testing\\tTesting.MyKey.Name\\tThis is a text string I am localizing. Wondering, can I have commas in a tsv?"
        let results = TSVFileParser.getColumnValues(from: lineTwo)
        XCTAssertTrue(results.count == 3, "Expected 3 Results")
    }
    
    func testParserEndToEndWithBasicFile() throws {
        guard let testFileURL = Bundle.module.url(forResource: "TestFile", withExtension: "tsv") else {
            return XCTFail("Could not open resource for test")
        }
        
        var locopipe = LocoPipe()
        locopipe.name = "Localizable"
        locopipe.input = testFileURL.path()
        locopipe.output = NSTemporaryDirectory()
        
        try locopipe.run()
        
        print("End to end test.  Output at: \(String(describing: locopipe.output))")
    }
}
