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

if let acctCookie = try? String(contentsOfFile: "acct.cookie"),
   let uauthCookie = try? String(contentsOfFile: "uauth.cookie") {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

    AF.sessionConfiguration.httpCookieStorage!.setCookie(
        HTTPCookie(properties: [
            .name: "acct",
            .value: acctCookie,
            .domain: ".stackexchange.com",
            .path: "/",
            .secure: true,
            .expires: formatter.date(from: "2023-11-13T00:11:40Z")! // TODO: get this somehow
        ])!)
    AF.sessionConfiguration.httpCookieStorage!.setCookie(
        HTTPCookie(properties: [
            .name: "uauth",
            .value: uauthCookie,
            .domain: ".codegolf.stackexchange.com",
            .path: "/",
            .secure: true,
            .expires: formatter.date(from: "2023-05-13T00:16:40Z")!
        ])!
    )
    print("Set cookies!")
} else {
    print("Enter your password:", terminator: " ")
    password = readLine()
}

do {
    print(try await auth.login(email: email, password: password, host: "codegolf.stackexchange.com"))
} catch {
    print("ERROR:", error)
}

print(AF.sessionConfiguration.httpCookieStorage?.cookies as Any)
