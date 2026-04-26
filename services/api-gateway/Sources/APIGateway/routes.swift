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
    users.get(":userID", "followers", use: proxyToIdentity)
    users.get(":userID", "following", use: proxyToIdentity)
    users.post(":userID", "follow", use: proxyToIdentity)
    users.delete(":userID", "follow", use: proxyToIdentity)

    v1.get("plants", use: proxyToPlants)
    v1.post("plants", use: proxyToPlants)
    v1.get("plants", ":plantID", use: proxyToPlants)
    v1.put("plants", ":plantID", use: proxyToPlants)
    v1.delete("plants", ":plantID", use: proxyToPlants)

    v1.get("plants", ":plantID", "care-events", use: proxyToPlants)
    v1.post("plants", ":plantID", "care-events", use: proxyToPlants)

    v1.get("plants", ":plantID", "photos", use: proxyToPlants)
    v1.post("plants", ":plantID", "photos", use: proxyToPlants)
    v1.delete("plants", ":plantID", "photos", ":photoID", use: proxyToPlants)

    v1.get("media", ":photoID", use: proxyToPlants)

    v1.get("posts", use: proxyToFeed)
    v1.get("posts", "global", use: proxyToFeed)
    v1.get("posts", ":postID", "comments", use: proxyToFeed)
    v1.post("posts", ":postID", "comments", use: proxyToFeed)
    v1.delete("posts", ":postID", "comments", ":commentID", use: proxyToFeed)

    v1.get("notifications", use: proxyToNotifications)
    v1.post("notifications", ":notificationID", "read", use: proxyToNotifications)
}
