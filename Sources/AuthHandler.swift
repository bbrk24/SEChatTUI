import SwiftSoup
import Alamofire

protocol AuthHandler {
    func login(email: String, password: String) async throws -> (fkey: String, id: String)
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

    func login(email: String, password: String) async throws -> (fkey: String, id: String) {
        let fkey = try await getFKey()

        try await client.sendRequest(
            .post,
            "https://meta.stackexchange.com/users/login-or-signup/validation/track",
            LoginModel(email: email, password: password, fkey: fkey)
        ).assertResponseCode()

        let loginResp = try await client.sendRequest(
            .post,
            "https://meta.stackexchange.com/users/login",
            LoadModel(email: email, password: password, fkey: fkey)
        )

        let loginEnc = Util.getEncoding(headers: loginResp.headers)
        guard let htmlStr = String(data: loginResp.data, encoding: loginEnc) else {
            throw SEChatTUIError.encodingMismatch(loginResp.data, loginEnc)
        }

        let title = try SwiftSoup.parse(htmlStr).title()
        if title.contains("Human verification") {
            throw SEChatTUIError.captcha
        }

        // FIXME: this 404's
        try await client.sendRequest(.post, "https://meta.stackexchange.com/users/login/universal/request", nil as Empty?).assertResponseCode()
        
        let chatFavoritesResp = try await client.sendRequest(.get, "https://chat.stackexchange.com/chats/join/favorite", nil as Empty?)
        let chatFavoritesEnc = Util.getEncoding(headers: chatFavoritesResp.headers)

        guard let htmlStr = String(data: chatFavoritesResp.data, encoding: chatFavoritesEnc) else {
            throw SEChatTUIError.encodingMismatch(chatFavoritesResp.data, chatFavoritesEnc)
        }
        let document = try SwiftSoup.parse(htmlStr)

        let userURLComponents = try document.select("a.topbar-menu-links").attr("href").split(separator: "/")
        if userURLComponents.count < 3 {
            throw SEChatTUIError.other("Couldn't determine chat user ID (URL components: \(userURLComponents))")
        }

        let chatFKey = try document.select("input[name=fkey]").attr("value")

        return (chatFKey, String(userURLComponents[2]))
    }
}
