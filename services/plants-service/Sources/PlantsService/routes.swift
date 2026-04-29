import Vapor

func routes(_ app: Application) throws {
    app.get("health") { _ in "OK" }
    try registerOpenAPIRoutes(app)

    let auth = JWTUserAuthenticator()
    let protected = app.grouped(auth).grouped(AuthenticatedUser.guardMiddleware())

    protected.get("plants", use: PlantController.index)
    protected.post("plants", use: PlantController.create)
    protected.get("plants", ":plantID", use: PlantController.show)
    protected.put("plants", ":plantID", use: PlantController.update)
    protected.delete("plants", ":plantID", use: PlantController.delete)

    protected.get("plants", ":plantID", "care-events", use: CareEventController.index)
    protected.post("plants", ":plantID", "care-events", use: CareEventController.create)

    protected.get("plants", ":plantID", "photos", use: PhotoController.index)
    protected.post("plants", ":plantID", "photos", use: PhotoController.upload)
    protected.delete("plants", ":plantID", "photos", ":photoID", use: PhotoController.delete)

    app.get("media", ":photoID", use: MediaController.serve)
}
