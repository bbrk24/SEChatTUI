import SwiftSoup
import Alamofire

protocol AuthHandler {
    func login(email: String, password: String) async throws
}

struct AuthHandlerImpl: AuthHandler {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getFKey() async throws -> String {
        let response = try await client.sendRequest(.get, "https://meta.stackexchange.com/users/login", nil as Empty?)
        let encoding = Util.getEncoding(headers: response.headers)

        guard let htmlStr = String(data: response.data, encoding: encoding) else {
            throw SEChatTUIError.encodingMismatch(response.data, encoding)
        }

        let fkey = try SwiftSoup.parse(htmlStr).getElementsByAttributeValue("name", "fkey").attr("value")
        return fkey
    }

    func login(email: String, password: String) async throws {
        let fkey = try await getFKey()

        _ = try await client.sendRequest(
            .post,
            "https://meta.stackexchange.com/users/login-or-signup/validation/track",
            LoginModel(email: email, password: password, fkey: fkey)
        )

        let response = try await client.sendRequest(
            .post,
            "https://meta.stackexchange.com/users/login",
            LoadModel(email: email, password: password, fkey: fkey)
        )

        let encoding = Util.getEncoding(headers: response.headers)
        guard let htmlStr = String(data: response.data, encoding: encoding) else {
            throw SEChatTUIError.encodingMismatch(response.data, encoding)
        }

        let title = try SwiftSoup.parse(htmlStr).title()
        if title.contains("Human verification") {
            throw SEChatTUIError.captcha
        }

        // FIXME: this 404's
        let response3 = try await client.sendRequest(.post, "https://meta.stackexchange.com/users/login/universal/request", nil as Empty?)
        print(response3)
    }
}
