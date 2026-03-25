import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let auth = app.grouped("auth")
    auth.post("register") { _ in
        // TODO: implement
        return HTTPStatus.notImplemented
    }

    auth.post("login") { _ in
        // TODO: implement
        return HTTPStatus.notImplemented
    }

    auth.post("refresh") { _ in
        // TODO: implement
        return HTTPStatus.notImplemented
    }

    auth.post("logout") { _ in
        // TODO: implement
        return HTTPStatus.notImplemented
    }
}

