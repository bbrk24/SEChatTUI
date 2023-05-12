import Foundation

enum SEChatTUIError: Error, CustomStringConvertible {
    case encodingMismatch(Data, String.Encoding)
    case captcha
    case badResponseCode(Int?)
    case other(String)

    var description: String {
        switch self {
        case .encodingMismatch(let data, let encoding):
            return "Encoding mismatch: \(data) is not decodable as \(encoding)"
        case .captcha:
            return "CAPTCHA encountered"
        case .badResponseCode(let code):
            if let code {
                return "Unexpected response code \(code)"
            } else {
                return "No HTTP status"
            }
        case .other(let desc):
            return desc
        }
    }
}
