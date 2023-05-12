// The Swift Programming Language
// https://docs.swift.org/swift-book

import Alamofire
import Foundation

// Adding `some` here causes a segfault
let httpClient: HTTPClient = HTTPClientImpl()
let auth: AuthHandler = AuthHandlerImpl(client: httpClient)

print("Enter your email address:", terminator: " ")
let email = readLine()!
var password: String?

if let cookie = try? String(contentsOfFile: "cookie") {
    AF.sessionConfiguration.httpCookieStorage!.setCookie(
        HTTPCookie(properties: [
            .name: "acct",
            .value: cookie,
            .domain: "stackexchange.com",
            .path: "/",
            .secure: true
        ])!
    )
    print("Set cookie!")
} else {
    print("Enter your password:", terminator: " ")
    password = readLine()
}

do {
    print(try await auth.login(email: email, password: password, host: "codegolf.stackexchange.com"))
} catch {
    print("ERROR:", error)
}
