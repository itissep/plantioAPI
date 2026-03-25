import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let v1 = app.grouped("v1")

    // Auth proxy placeholder
    v1.get("auth", "health") { _ in
        // later: proxy to identity-service
        return HTTPStatus.notImplemented
    }
}

