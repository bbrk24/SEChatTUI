// The Swift Programming Language
// https://docs.swift.org/swift-book

import Alamofire
import Foundation

try await { // IIFE, so as not to pollute the global namespace

let host = "codegolf.stackexchange.com"

// Adding `some` here causes a segfault
let httpClient: some HTTPClient = HTTPClientImpl()
let auth: some AuthHandler = AuthHandlerImpl(client: httpClient)

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
        .expires: Date().addingTimeInterval(1)
    ])!)
}

let user = try await auth.login(email: email, password: password, host: host)

let room = Room(user: user, id: 1, client: httpClient)
try await room.send(message: "Does it still work?")

}()