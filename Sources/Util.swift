import Foundation

enum Util {
    static func getEncoding(headers: [String: String]) -> String.Encoding {
        // If there's no Content-Type header, we can't know; assume ASCII
        guard let contentType = headers["Content-Type"] else { return .ascii }

        // Try to parse out the charset
        let charset = contentType.split(separator: ";").lazy.compactMap {
            let trimmedLower = $0.trimmingCharacters(in: .whitespaces).lowercased()
            if trimmedLower.hasPrefix("charset=") {
                return trimmedLower.dropFirst("charset=".count)
            } else {
                return nil
            }
        }
            .first
        
        // https://www.iana.org/assignments/character-sets/character-sets.xhtml
        switch charset {
        // SE seems to (almost?) always use one of these two, so put them first
        case "utf-8", "csutf8":
            return .utf8
        case nil, "us-ascii", "iso-ir-6", "ansi_x3.4-1968", "ansi_x3.4-1986", "iso_646.irv:1991", "iso646-us", "us", "ib367", "cp367", "csascii":
            return .ascii
        // It could feasibly use UTF-16 or Latin-1, but I haven't seen it
        case "utf-16", "csutf16":
            return .utf16
        case "utf-16be", "csutf16be":
            return .utf16BigEndian
        case "utf-16le", "csutf16le":
            return .utf16LittleEndian
        case "iso-8859-1", "iso-ir-100", "iso_8859-1", "l1", "ibm819", "cp819", "csisolatin1":
            return .isoLatin1
        // Unlikely but supported encodings
        case "iso-2022-jp", "csiso2022jp":
            return .iso2022JP
        case "iso-8859-2", "iso-ir-101", "iso_8859-2", "l2", "csisolatin2":
            return .isoLatin2
        case "euc-jp", "cseucpkdfmtjapanese":
            return .japaneseEUC
        case "macintosh", "mac", "csmacintosh":
            return .macOSRoman
        case "shift_jis", "ms_kanji", "csshiftjis":
            return .shiftJIS
        case "utf-32", "csutf32":
            return .utf32
        case "utf-32be", "csutf32be":
            return .utf32BigEndian
        case "utf-32le", "csutf32le":
            return .utf32LittleEndian
        case "windows-1250", "cswindows1250":
            return .windowsCP1250
        case "windows-1251", "cswindows1251":
            return .windowsCP1251
        case "windows-1252", "cswindows1252":
            return .windowsCP1252
        case "windows-1253", "cswindows1253":
            return .windowsCP1253
        case "windows-1254", "cswindows1254":
            return .windowsCP1254
        // Uh
        default:
            return .ascii
        }
    }

    static func getDataString(_ response: HTTPResponse) throws -> String {
        let enc = getEncoding(headers: response.headers)
        guard let str = String(data: response.data, encoding: enc) else {
            throw SEChatTUIError.encodingMismatch(response.data, enc)
        }
        return str
    }

    static var paramcharset: CharacterSet = {
        var paramcharset = CharacterSet.urlQueryAllowed
        paramcharset.remove(charactersIn: "?&=;")
        return paramcharset
    }()

    @discardableResult
    static func setInterval(seconds interval: TimeInterval, tolerance: TimeInterval = 0.004, action: @escaping () -> Void) -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in action() }
        timer.tolerance = tolerance
        return timer
    }
}
