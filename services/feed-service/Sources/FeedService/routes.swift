import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let posts = app.grouped("posts")
    posts.get { _ in
        // TODO: implement list posts
        return HTTPStatus.notImplemented
    }
}

