import Fluent
import Vapor

final class Follow: Model {
    static let schema = "follows"

    @ID
    var id: UUID?

    @Field(key: "follower_id")
    var followerID: UUID

    @Field(key: "following_id")
    var followingID: UUID

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, followerID: UUID, followingID: UUID) {
        self.id = id
        self.followerID = followerID
        self.followingID = followingID
    }
}
