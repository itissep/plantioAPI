import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let v1 = app.grouped("v1")

    v1.post("auth", "register", use: proxyToIdentity)
    v1.post("auth", "login", use: proxyToIdentity)
    v1.post("auth", "refresh", use: proxyToIdentity)
    v1.post("auth", "logout", use: proxyToIdentity)

    let users = v1.grouped("users")
    users.get("me", use: proxyToIdentity)
    users.put("me", use: proxyToIdentity)
    users.get(":userID", use: proxyToIdentity)
    users.post(":userID", "follow", use: proxyToIdentity)
    users.delete(":userID", "follow", use: proxyToIdentity)
}
