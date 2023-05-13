import SwiftSoup
import Alamofire

protocol AuthHandler {
    func login(email: String, password: String?, host: String) async throws -> (fkey: String, id: String)
}

struct AuthHandlerImpl: AuthHandler {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getFKey(_ host: String) async throws -> String {
        let response = try await client.sendRequest(
            .get,
            "https://\(host)/users/login",
            headers: [
                "Referer": "https://\(host)/"
            ],
            body: nil as Empty?
        )
        let encoding = Util.getEncoding(headers: response.headers)

        guard let htmlStr = String(data: response.data, encoding: encoding) else {
            throw SEChatTUIError.encodingMismatch(response.data, encoding)
        }

        let fkey = try SwiftSoup.parse(htmlStr).getElementsByAttributeValue("name", "fkey").attr("value")
        return fkey
    }

    func login(email: String, password: String?, host: String) async throws -> (fkey: String, id: String) {
        let fkey = try await getFKey(host)

        if let password, !password.isEmpty {
            let baseURL = "https://\(host)/"

            // Firefox doesn't show me ANYTHING about this request. There's no headers, no cookies, no request body, no response body, no timings, NOTHING.
            // I could be missing a header or sending the wrong payload and have no idea.
            try await client.sendRequest(
                .post,
                "https://\(host)/users/login-or-signup/validation/track",
                headers: [:],
                body: LoginModel(email: email, password: password, fkey: fkey)
            ).assertResponseCode()

            let loginURL = "https://\(host)/users/login?ssrc=head&returnurl=\(baseURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
            let loginResp = try await client.sendRequest(
                .post,
                loginURL,
                headers: [
                    "Origin": "https://" + host,
                    "Referer": loginURL
                ],
                body: LoadModel(email: email, password: password, fkey: fkey)
            )

            let htmlStr = try Util.getDataString(loginResp)

            let title = try SwiftSoup.parse(htmlStr).title()
            if title.contains("Human verification") {
                throw SEChatTUIError.captcha
            }
        }
        
        let chatFavoritesResp = try await client.sendRequest(
            .get,
            "https://chat.stackexchange.com/chats/join/favorite",
            headers: [:],
            body: nil as Empty?
        )

        let htmlStr = try Util.getDataString(chatFavoritesResp)
        let document = try SwiftSoup.parse(htmlStr)

        let userURLComponents = try document.select(".topbar-menu-links a").attr("href").split(separator: "/")
        if userURLComponents.count < 3 {
            throw SEChatTUIError.htmlParserError("Couldn't determine chat user ID (URL components: \(userURLComponents))")
        }

        let chatFKey = try document.select("input[name=fkey]").attr("value")

        return (chatFKey, String(userURLComponents[2]))
    }
}
