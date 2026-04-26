import Foundation
import Vapor

struct CommentCreatedPayload: Codable {
    var event: String
    var commentId: UUID
    var postId: UUID
    var postAuthorId: UUID
    var authorId: UUID
    var text: String
}

protocol CommentPublisher: Sendable {
    func publishCommentCreated(
        commentID: UUID,
        postID: UUID,
        postAuthorID: UUID,
        authorID: UUID,
        text: String,
        client: Client,
        logger: Logger
    ) async
}

struct RabbitMQCommentPublisher: CommentPublisher {
    private let exchange = "feed.events"
    private let routingKey = "comment.created"

    private var host: String { Environment.get("RABBITMQ_HOST") ?? "rabbitmq" }
    private var user: String { Environment.get("RABBITMQ_USER") ?? "guest" }
    private var password: String { Environment.get("RABBITMQ_PASSWORD") ?? "guest" }
    private var managementPort: String { Environment.get("RABBITMQ_MANAGEMENT_PORT") ?? "15672" }

    private var vhostEncoded: String {
        let raw = Environment.get("RABBITMQ_VHOST") ?? "/"
        return raw == "/" ? "%2F" : (raw.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? raw)
    }

    private var basicAuth: String {
        "Basic " + Data("\(user):\(password)".utf8).base64EncodedString()
    }

    func publishCommentCreated(
        commentID: UUID,
        postID: UUID,
        postAuthorID: UUID,
        authorID: UUID,
        text: String,
        client: Client,
        logger: Logger
    ) async {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .authorization, value: basicAuth)
        headers.replaceOrAdd(name: .contentType, value: "application/json")

        // объявляем exchange
        let exchangeURI = URI(string: "http://\(host):\(managementPort)/api/exchanges/\(vhostEncoded)/\(exchange)")
        var exchangeReq = ClientRequest(method: .PUT, url: exchangeURI, headers: headers)
        exchangeReq.body = ByteBuffer(string: #"{"type":"topic","durable":true}"#)
        _ = try? await client.send(exchangeReq)

        let payload = CommentCreatedPayload(
            event: "CommentCreated",
            commentId: commentID,
            postId: postID,
            postAuthorId: postAuthorID,
            authorId: authorID,
            text: text
        )

        guard let payloadData = try? JSONEncoder().encode(payload),
              let payloadStr = String(data: payloadData, encoding: .utf8) else { return }

        let escaped = payloadStr.replacingOccurrences(of: "\\", with: "\\\\")
                                .replacingOccurrences(of: "\"", with: "\\\"")
        let body = #"{"properties":{},"routing_key":"\#(routingKey)","payload":"\#(escaped)","payload_encoding":"string"}"#

        let publishURI = URI(string: "http://\(host):\(managementPort)/api/exchanges/\(vhostEncoded)/\(exchange)/publish")
        var publishReq = ClientRequest(method: .POST, url: publishURI, headers: headers)
        publishReq.body = ByteBuffer(string: body)

        do {
            _ = try await client.send(publishReq)
            logger.info("CommentPublisher: published comment.created")
        } catch {
            logger.warning("CommentPublisher: failed to publish: \(error)")
        }
    }
}

struct NoOpCommentPublisher: CommentPublisher {
    func publishCommentCreated(commentID: UUID, postID: UUID, postAuthorID: UUID, authorID: UUID, text: String, client: Client, logger: Logger) async {}
}
