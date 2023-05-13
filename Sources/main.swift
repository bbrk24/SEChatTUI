// The Swift Programming Language
// https://docs.swift.org/swift-book

import Alamofire
import Foundation

let host = "codegolf.stackexchange.com"

// Adding `some` here causes a segfault
let httpClient: HTTPClient = HTTPClientImpl()
let auth: AuthHandler = AuthHandlerImpl(client: httpClient)

print("Enter your email address:", terminator: " ")
let email = readLine()!
var password: String?

if let acctCookie = try? String(contentsOfFile: "acct.cookie"),
   let uauthCookie = try? String(contentsOfFile: "uauth.cookie") {
    AF.sessionConfiguration.httpCookieStorage!.setCookie(HTTPCookie(properties: [
        .name: "acct",
        .value: acctCookie,
        .domain: ".stackexchange.com",
        .path: "/",
        .secure: "TRUE"
    ])!)
    AF.sessionConfiguration.httpCookieStorage!.setCookie(HTTPCookie(properties: [
        .name: "uauth",
        .value: uauthCookie,
        .domain: "." + host,
        .path: "/",
        .secure: "TRUE"
    ])!)
    print("Set cookies!")
} else {
    print("Enter your password:", terminator: " ")
    password = readLine()
}

if let sechatusrCookie = try? String(contentsOfFile: "sechatusr.cookie") {
    AF.sessionConfiguration.httpCookieStorage!.setCookie(HTTPCookie(properties: [
        .name: "sechatusr",
        .value: sechatusrCookie,
        .originURL: URL(string: "https://chat.stackexchange.com")!,
        .path: "/",
        .secure: "TRUE",
        // sechatusr cookies expire stupid fast
        .expires: Date().addingTimeInterval(1)
    ])!)
}

let user = try await auth.login(email: email, password: password, host: host)
let room = Room(user: user, id: 145982, client: httpClient)
try await room.send(message: "Does it still work?")

let sechatusrCookie = AF.sessionConfiguration.httpCookieStorage!.cookies!.first { $0.name == "sechatusr" }!.value
try? sechatusrCookie.write(toFile: "sechatusr.cookie", atomically: false, encoding: .utf8)
