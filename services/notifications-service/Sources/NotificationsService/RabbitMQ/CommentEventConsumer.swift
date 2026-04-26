import Foundation
import Vapor

private struct CommentCreatedPayload: Codable {
    var event: String
    var commentId: UUID
    var postId: UUID
    var postAuthorId: UUID
    var authorId: UUID
    var text: String
}

private struct ManagementMessage: Codable {
    var payload: String
    var payload_encoding: String
}

actor CommentEventConsumer {
    private let app: Application
    private let exchange = "feed.events"
    private let queue = "notifications.comments"
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

    init(app: Application) {
        self.app = app
    }

    func start() async {
        app.logger.info("CommentEventConsumer: starting")
        await setupInfra()
        await pollLoop()
    }

    private func setupInfra() async {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .authorization, value: basicAuth)
        headers.replaceOrAdd(name: .contentType, value: "application/json")

        let exchangeURI = URI(string: "http://\(host):\(managementPort)/api/exchanges/\(vhostEncoded)/\(exchange)")
        var exchangeReq = ClientRequest(method: .PUT, url: exchangeURI, headers: headers)
        exchangeReq.body = ByteBuffer(string: #"{"type":"topic","durable":true}"#)
        _ = try? await app.client.send(exchangeReq)

        let queueURI = URI(string: "http://\(host):\(managementPort)/api/queues/\(vhostEncoded)/\(queue)")
        var queueReq = ClientRequest(method: .PUT, url: queueURI, headers: headers)
        queueReq.body = ByteBuffer(string: #"{"durable":true}"#)
        _ = try? await app.client.send(queueReq)

        let bindURI = URI(string: "http://\(host):\(managementPort)/api/bindings/\(vhostEncoded)/e/\(exchange)/q/\(queue)")
        var bindReq = ClientRequest(method: .POST, url: bindURI, headers: headers)
        bindReq.body = ByteBuffer(string: #"{"routing_key":"\#(routingKey)"}"#)
        _ = try? await app.client.send(bindReq)

        app.logger.info("CommentEventConsumer: exchange, queue and binding ready")
    }

    private func pollLoop() async {
        while !Task.isCancelled {
            await pollOnce()
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    private func pollOnce() async {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .authorization, value: basicAuth)
        headers.replaceOrAdd(name: .contentType, value: "application/json")

        let getURI = URI(string: "http://\(host):\(managementPort)/api/queues/\(vhostEncoded)/\(queue)/get")
        var getReq = ClientRequest(method: .POST, url: getURI, headers: headers)
        getReq.body = ByteBuffer(string: #"{"count":10,"ackmode":"ack_requeue_false","encoding":"auto"}"#)

        guard let res = try? await app.client.send(getReq),
              res.status == .ok,
              var buffer = res.body,
              let data = buffer.readData(length: buffer.readableBytes),
              let messages = try? JSONDecoder().decode([ManagementMessage].self, from: data),
              !messages.isEmpty else { return }

        for message in messages {
            await handleMessage(message.payload)
        }
    }

    private func handleMessage(_ payloadString: String) async {
        guard let data = payloadString.data(using: .utf8),
              let payload = try? JSONDecoder().decode(CommentCreatedPayload.self, from: data) else {
            app.logger.warning("CommentEventConsumer: failed to decode payload")
            return
        }

        let preview = payload.text.count > 50
            ? String(payload.text.prefix(50)) + "..."
            : payload.text

        let notification = Notification(
            userID: payload.postAuthorId,
            title: "New comment",
            body: "Someone commented on your post: \"\(preview)\"",
            careEventID: payload.postId,
            plantID: payload.postId
        )

        do {
            try await notification.save(on: app.db)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let jsonData = try? encoder.encode(NotificationDTO(from: notification)),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                await app.wsManager.send(jsonString, to: payload.postAuthorId)
            }
            app.logger.info("CommentEventConsumer: notification saved for user \(payload.postAuthorId)")
        } catch {
            app.logger.warning("CommentEventConsumer: failed to save notification: \(error)")
        }
    }
}

struct CommentEventConsumerLifecycle: LifecycleHandler {
    func didBoot(_ application: Application) throws {
        let consumer = CommentEventConsumer(app: application)
        Task {
            await consumer.start()
        }
    }
}
