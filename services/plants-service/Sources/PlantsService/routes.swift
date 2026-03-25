import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in
        "OK"
    }

    let plants = app.grouped("plants")
    plants.get { _ in
        // TODO: implement list plants
        return HTTPStatus.notImplemented
    }
}

