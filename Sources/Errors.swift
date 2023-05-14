import Foundation

enum SEChatTUIError: Error, CustomStringConvertible {
    case encodingMismatch(Data, String.Encoding, file: StaticString = #fileID, line: UInt = #line)
    case captcha(file: StaticString = #fileID, line: UInt = #line)
    case badResponseCode(Int?, file: StaticString = #fileID, line: UInt = #line)
    case htmlParserError(String, file: StaticString = #fileID, line: UInt = #line)
    case notLoggedIn(HTTPResponse?, file: StaticString = #fileID, line: UInt = #line)

    var description: String {
        switch self {
        case .encodingMismatch(let data, let encoding, let file, let line):
            return "\(file):\(line): Encoding mismatch: \(data) is not decodable as \(encoding)"
        case .captcha(let file, let line):
            return "\(file):\(line): CAPTCHA encountered"
        case .badResponseCode(let code, let file, let line):
            if let code {
                return "\(file):\(line): Unexpected response code \(code)"
            } else {
                return "\(file):\(line): No HTTP status"
            }
        case .htmlParserError(let desc, let file, let line):
            return "\(file):\(line): HTML parsing error: \(desc)"
        case .notLoggedIn(let resp, let file, let line):
            if let resp {
                return "\(file):\(line): Unable to log in: \(resp)"
            } else {
                return "\(file):\(line): Unable to log in"
            }
        }
    }

    var location: (file: StaticString, line: UInt) { 
        switch self {
        case .encodingMismatch(_, _, let file, let line),
            .captcha(let file, let line),
            .badResponseCode(_, let file, let line),
            .htmlParserError(_, let file, let line),
            .notLoggedIn(_, let file, let line):
            return (file, line)
        }
    }
}
