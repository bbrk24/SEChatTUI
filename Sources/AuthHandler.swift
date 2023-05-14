import SwiftSoup
import Alamofire
import Foundation

protocol AuthHandler {
    func login(email: String, password: String?, host: String) async throws -> User
}

struct AuthHandlerImpl: AuthHandler {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func getFKey() async throws -> String {
        let response = try await client.sendRequest(
            .get,
            "https://meta.stackexchange.com/users/login",
            headers: [
                "Referer": "https://meta.stackexchange.com/"
            ],
            body: nil as Empty?
        )
        let encoding = Util.getEncoding(headers: response.headers)

        guard let htmlStr = String(data: response.data, encoding: encoding) else {
            throw SEChatTUIError.encodingMismatch(response.data, encoding)
        }

        let fkey = try SwiftSoup.parse(htmlStr).select("input[name=fkey]").attr("value")
        return fkey
    }

    func login(email: String, password: String?, host: String) async throws -> User {
        let baseURL = "https://\(host)/"

        if let password, !password.isEmpty {
            let fkey = try await getFKey()

            let trackResp = try await client.sendRequest(
                .post,
                "https://\(host)/users/login-or-signup/validation/track",
                headers: [:],
                body: LoginModel(email: email, password: password, fkey: fkey)
            )
            try trackResp.assertResponseCode()
            if try Util.getDataString(trackResp) != "Login-OK" {
                throw SEChatTUIError.notLoggedIn(trackResp)
            }

            let loginURL = "https://\(host)/users/login?ssrc=head&returnurl=\(baseURL.addingPercentEncoding(withAllowedCharacters: Util.paramcharset)!)"
            let loginResp = try await client.sendRequest(
                .post,
                loginURL,
                headers: [
                    "Origin": "https://" + host,
                    "Referer": loginURL
                ],
                body: LoadModel(email: email, password: password, fkey: fkey)
            )

            let loginHTMLStr = try Util.getDataString(loginResp)
            try loginHTMLStr.write(toFile: "login.html", atomically: false, encoding: .utf8)

            let title = try SwiftSoup.parse(loginHTMLStr).title()
            if title.contains("Human verification") {
                throw SEChatTUIError.captcha()
            }
        }

        guard let cookies = AF.sessionConfiguration.httpCookieStorage?.cookies,
              cookies.contains(where: { $0.name == "acct" }) else {
            throw SEChatTUIError.notLoggedIn(nil)
        }

        let chatResp = try await client.sendRequest(
            .get,
            "https://chat.stackexchange.com/chats/join/favorite",
            headers: [
                "Referer": baseURL
            ],
            body: nil as Empty?
        )
        try chatResp.assertResponseCode()

        let chatHTMLStr = try Util.getDataString(chatResp)
        let document = try SwiftSoup.parse(chatHTMLStr)

        let userURLComponents = try document.select(".topbar-menu-links a").attr("href").split(separator: "/")
        guard userURLComponents.count == 3, let chatID = Int(userURLComponents[1]) else {
            throw SEChatTUIError.htmlParserError(
                "Couldn't determine chat user ID (URL components: \(userURLComponents)). This probably means login failed."
            )
        }

        let chatFKey = try document.select("input[name=fkey]").attr("value")

        guard cookies.contains(where: { $0.name == "sechatusr" }) else {
            throw SEChatTUIError.notLoggedIn(chatResp)
        }

        return User(fkey: chatFKey, id: chatID)
    }
}
