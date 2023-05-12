// The Swift Programming Language
// https://docs.swift.org/swift-book

import Alamofire

// Adding `some` here causes a segfault
let httpClient: HTTPClient = HTTPClientImpl()
let auth: AuthHandler = AuthHandlerImpl(client: httpClient)

print("Enter your email address:", terminator: " ")
let email = readLine()!
print("Enter your password:", terminator: " ")
let password = readLine()!

print(try await auth.login(email: email, password: password))
print(AF.sessionConfiguration.httpCookieStorage?.cookies as Any)
print(AF.sessionConfiguration.urlCredentialStorage?.allCredentials as Any)
