import Foundation

public class ConsoleIO {
    
    enum OutputType {
        case error
        case debug
        case standard
    }
    
    static func write(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\(message)")
        case .debug:
            fputs("Debug: \(message)\n", stderr)
        case .error:
            fputs("Error: \(message)\n", stderr)
        }
    }
    
    static func log(_ message: String) {
        self.write(message, to: .standard)
    }
    
    static func logDebug(_ message: String) {
        self.write(message, to: .debug)
    }
    
    static func logError(_ message: String) {
        self.write(message, to: .error)
    }
}
