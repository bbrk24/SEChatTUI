import SwiftSoup
import Alamofire
import Foundation

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

        var paramcharset = CharacterSet.urlQueryAllowed
        paramcharset.remove(charactersIn: "?&=;")

        if let password, !password.isEmpty {
            let baseURL = "https://\(host)/"

            try await client.sendRequest(
                .post,
                "https://\(host)/users/login-or-signup/validation/track?email=\(email)&password=\(password.addingPercentEncoding(withAllowedCharacters: paramcharset)!)&fkey=\(fkey)&isSignup=false&isLogin=true&isPassword=false&isAddLogin=false&hasCaptcha=false&ssrc=head&submitButton=Log%20In",
                headers: [:],
                body: nil as Empty?
            ).assertResponseCode()

            let loginURL = "https://\(host)/users/login?ssrc=head&returnurl=\(baseURL.addingPercentEncoding(withAllowedCharacters: paramcharset)!)"
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
                throw SEChatTUIError.captcha
            }
        }
        
        let chatFavoritesResp = try await client.sendRequest(
            .get,
            "https://chat.stackexchange.com/chats/join/favorite",
            headers: [:],
            body: nil as Empty?
        )

        let chatFavoritesHTMLStr = try Util.getDataString(chatFavoritesResp)
        let document = try SwiftSoup.parse(chatFavoritesHTMLStr)

        // FIXME: what is going on here
        // let userURLComponents = try document.select(".topbar-menu-links a").attr("href").split(separator: "/")
        // if userURLComponents.count != 3 {
        //     throw SEChatTUIError.htmlParserError("Couldn't determine chat user ID (URL components: \(userURLComponents))")
        // }
        // let chatID = String(userURLComponents[2])
        let chatID = "543214"

        let chatFKey = try document.select("input[name=fkey]").attr("value")

        return (chatFKey, chatID)
    }
}
