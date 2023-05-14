import Alamofire
import Foundation

struct HTTPResponse: CustomDebugStringConvertible {
    var headers: [String: String]
    var data: Data
    var statusCode: Int?

    var debugDescription: String {
        var dataString: String
        if let str = String(data: data, encoding: .utf8) {
            dataString = str.prefix(1536).debugDescription
        } else {
            dataString = "<\(data.count) bytes>"
        }

        let firstPart = "HTTPResponse(headers: \(headers), data: \(dataString)"
        if let statusCode {
            return "\(firstPart), statusCode: \(statusCode))"
        } else {
            return firstPart + ")"
        }
    }

    func assertResponseCode(
        in range: some RangeExpression<Int> = 200..<300,
        _const file: StaticString = #fileID,
        _const line: UInt = #line
    ) throws {
        guard let statusCode,
              range.contains(statusCode) else {
            throw SEChatTUIError.badResponseCode(statusCode, file: file, line: line)
        }
    }
}

protocol HTTPClient {
    func sendRequest(
        _ method: HTTPMethod,
        _ url: URLConvertible,
        headers: HTTPHeaders,
        body: (some Encodable)?
    ) async throws -> HTTPResponse
}

struct HTTPClientImpl: HTTPClient {
    private let encoder: ParameterEncoder

    init() {
        self.encoder = URLEncodedFormParameterEncoder(
            encoder: .init(
                alphabetizeKeyValuePairs: false,
                boolEncoding: .literal,
                nilEncoding: .dropValue,
                spaceEncoding: .plusReplaced,
                allowedCharacters: Util.paramcharset
            ),
            destination: .httpBody
        )

        let sessionConfiguration = AF.sessionConfiguration
        sessionConfiguration.httpCookieStorage = .shared
        sessionConfiguration.httpCookieAcceptPolicy = .always
        sessionConfiguration.httpShouldSetCookies = true
        sessionConfiguration.httpCookieStorage?.cookieAcceptPolicy = .always
        sessionConfiguration.headers.add(.init(
            name: "User-Agent",
            // I haven't assigned versions yet so just 0.0.1 for now
            value: "Mozilla/5.0 (compatible; automated; +https://github.com/bbrk24/SEChatTUI) SEChatTUI/0.0.1"
        ))
    }

    func sendRequest(
        _ method: HTTPMethod,
        _ url: URLConvertible,
        headers: HTTPHeaders,
        body: (some Encodable)?
    ) async throws -> HTTPResponse {
        let req = AF.request(
            url,
            method: method,
            parameters: body,
            encoder: self.encoder,
            headers: headers
        )

        let resp = await req.serializingData(emptyResponseCodes: [204, 205, 404]).response

        return try resp.result.map {
            HTTPResponse(
                headers: resp.response?.headers.dictionary ?? [:],
                data: $0,
                statusCode: resp.response?.statusCode
            )
        }.get()
    }
}
