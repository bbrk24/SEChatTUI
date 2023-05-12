import Foundation

enum SEChatTUIError: Error, CustomStringConvertible {
    case encodingMismatch(Data, String.Encoding)
    case captcha

    var description: String {
        switch self {
        case .encodingMismatch(let data, let encoding):
            return "Encoding mismatch: \(data) is not decodable as \(encoding)"
        case .captcha:
            return "CAPTCHA encountered"
        }
    }
}
