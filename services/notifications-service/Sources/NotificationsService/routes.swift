import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    app.webSocket("ws") { req, ws in
        // TODO: JWT auth and sessions
        ws.send("connected")
    }
}

