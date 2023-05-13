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

    func login(email: String, password: String?, host: String) async throws -> User {
        let fkey = try await getFKey(host)
        let baseURL = "https://\(host)/"

        if let password, !password.isEmpty {
            try await client.sendRequest(
                .post,
                "https://\(host)/users/login-or-signup/validation/track?email=\(email)&password=\(password.addingPercentEncoding(withAllowedCharacters: Util.paramcharset)!)&fkey=\(fkey)&isSignup=false&isLogin=true&isPassword=false&isAddLogin=false&hasCaptcha=false&ssrc=head&submitButton=Log%20In",
                headers: [:],
                body: nil as Empty?
            ).assertResponseCode()

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

            let title = try SwiftSoup.parse(loginHTMLStr).title()
            if title.contains("Human verification") {
                throw SEChatTUIError.captcha()
            }

            print(AF.sessionConfiguration.httpCookieStorage?.cookies as Any)
        }

        // // Fire and forget this request. Other clients use it, and it doesn't do any harm, but it doesn't seem to do anything.
        // Task { [client] in // Capture [client] explicitly as not to capture [self] implicitly
        //     try? await client.sendRequest(
        //         .post, 
        //         "https://\(host)/users/login/universal/request",
        //         headers: [:],
        //         body: nil as Empty?
        //     )
        // }

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

        return User(fkey: chatFKey, id: chatID)
    }
}
