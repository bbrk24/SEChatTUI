import Alamofire
import Foundation

struct HTTPResponse: CustomDebugStringConvertible {
    var headers: [String: String]
    var data: Data
    var statusCode: Int?

    var debugDescription: String {
        var dataString: String
        if let str = String(data: data, encoding: .utf8) {
            dataString = str.debugDescription
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
}

protocol HTTPClient {
    func sendRequest(
        _ method: HTTPMethod,
        _ url: URLConvertible,
        _ body: (some Encodable)?
    ) async throws -> HTTPResponse
}

struct HTTPClientImpl: HTTPClient {
    init() {
        let sessionConfiguration = AF.sessionConfiguration

        sessionConfiguration.httpCookieAcceptPolicy = .always
        sessionConfiguration.httpShouldSetCookies = true
    }

    func sendRequest(
        _ method: HTTPMethod,
        _ url: URLConvertible,
        _ body: (some Encodable)?
    ) async throws -> HTTPResponse {
        let req = AF.request(
            url,
            method: method,
            parameters: body,
            encoder: JSONParameterEncoder.default
        )

        let resp = await req.serializingData().response

        return try resp.result.map {
            HTTPResponse(
                headers: resp.response?.headers.dictionary ?? [:],
                data: $0,
                statusCode: resp.response?.statusCode
            )
        }.get()
    }
}
