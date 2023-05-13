import Foundation
import Alamofire

struct Room: Identifiable {
    let user: User
    let id: Int
    let client: HTTPClient

    func send(message: String) async throws {
        print(AF.sessionConfiguration.httpCookieStorage?.cookies as Any)
        print(try await client.sendRequest(
            .post,
            "https://chat.stackexchange.com/chats/\(id)/messages/new",
            headers: [
                "Referer": "https://chat.stackexchange.com/chats/\(id)/",
                "Origin": "https://chat.stackexchange.com"
            ],
            body: NewMessage(text: message, fkey: user.fkey)
        ))
    }
}
