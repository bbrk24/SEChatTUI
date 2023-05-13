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
    var submitButton = "Log In"
}

struct LoadModel: Encodable {
    var email: String
    var password: String
    var fkey: String
    var ssrc = "head"
    var oauth_version = ""
    var oauth_server = ""
}
