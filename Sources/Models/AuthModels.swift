struct LoadModel: Encodable {
    var email: String
    var password: String
    var ssrc = "head"
    var fkey: String
}

struct LoginModel: Encodable {
    var email: String
    var password: String
    var fkey: String
    var isSignup = false
    var isLogin = true
    var isPassword = false
    var isAddLogin = false
    var hasCaptcha = false
    var ssrc = "head"
    var submitButton = "Log in"
}

struct User: Identifiable {
    var fkey: String
    var id: Int
}
