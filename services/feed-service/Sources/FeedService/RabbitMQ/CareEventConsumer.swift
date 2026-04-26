import Foundation
import Vapor

struct CareEventCreatedPayload: Codable {
    var event: String
    var careEventId: UUID
    var plantId: UUID
    var userId: UUID
    var kind: String
    var occurredAt: Date
}

private struct FollowerIDsResponse: Codable {
    var followerIDs: [UUID]
}

private struct ManagementMessage: Codable {
    var payload: String
    var payload_encoding: String
}

private struct GetMessagesRequest: Encodable {
    var count: Int = 10
    var ackmode: String = "ack_requeue_false"
    var encoding: String = "auto"
}

actor CareEventConsumer {
    private let app: Application
    private let exchange = "plants.events"
    private let queue = "feed.care_events"
    private let routingKey = "care_event.created"

    private var host: String { Environment.get("RABBITMQ_HOST") ?? "rabbitmq" }
    private var user: String { Environment.get("RABBITMQ_USER") ?? "guest" }
    private var password: String { Environment.get("RABBITMQ_PASSWORD") ?? "guest" }
    private var managementPort: String { Environment.get("RABBITMQ_MANAGEMENT_PORT") ?? "15672" }
    private var identityURL: String { Environment.get("IDENTITY_SERVICE_URL") ?? "http://localhost:3001" }

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
        app.logger.info("CareEventConsumer: starting")
        await setupInfra()
        await pollLoop()
    }

    private func setupInfra() async {
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .authorization, value: basicAuth)
        headers.replaceOrAdd(name: .contentType, value: "application/json")

        // declare exchange
        let exchangeURI = URI(string: "http://\(host):\(managementPort)/api/exchanges/\(vhostEncoded)/\(exchange)")
        var exchangeReq = ClientRequest(method: .PUT, url: exchangeURI, headers: headers)
        exchangeReq.body = ByteBuffer(string: #"{"type":"topic","durable":true}"#)
        _ = try? await app.client.send(exchangeReq)

        // declare queue
        let queueURI = URI(string: "http://\(host):\(managementPort)/api/queues/\(vhostEncoded)/\(queue)")
        var queueReq = ClientRequest(method: .PUT, url: queueURI, headers: headers)
        queueReq.body = ByteBuffer(string: #"{"durable":true}"#)
        _ = try? await app.client.send(queueReq)

        // bind queue to exchange
        let bindURI = URI(string: "http://\(host):\(managementPort)/api/bindings/\(vhostEncoded)/e/\(exchange)/q/\(queue)")
        var bindReq = ClientRequest(method: .POST, url: bindURI, headers: headers)
        bindReq.body = ByteBuffer(string: #"{"routing_key":"\#(routingKey)"}"#)
        _ = try? await app.client.send(bindReq)

        app.logger.info("CareEventConsumer: exchange, queue and binding ready")
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
        let body = #"{"count":10,"ackmode":"ack_requeue_false","encoding":"auto"}"#
        var getReq = ClientRequest(method: .POST, url: getURI, headers: headers)
        getReq.body = ByteBuffer(string: body)

        guard let res = try? await app.client.send(getReq),
              res.status == .ok,
              var buffer = res.body,
              let data = buffer.readData(length: buffer.readableBytes) else { return }

        guard let messages = try? JSONDecoder().decode([ManagementMessage].self, from: data),
              !messages.isEmpty else { return }

        for message in messages {
            await handleMessage(message.payload)
        }
    }

    private func handleMessage(_ payloadString: String) async {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = payloadString.data(using: .utf8),
              let payload = try? decoder.decode(CareEventCreatedPayload.self, from: data) else {
            app.logger.warning("CareEventConsumer: failed to decode payload")
            return
        }

        app.logger.info("CareEventConsumer: received care_event.created for plant \(payload.plantId)")

        let followerIDs = await fetchFollowers(of: payload.userId)
        guard !followerIDs.isEmpty else { return }

        await saveFeedPosts(payload: payload, followerIDs: followerIDs)
    }

    private func fetchFollowers(of userID: UUID) async -> [UUID] {
        let url = "\(identityURL)/internal/users/\(userID)/followers"
        guard let res = try? await app.client.get(URI(string: url)),
              res.status == .ok,
              var buffer = res.body,
              let data = buffer.readData(length: buffer.readableBytes),
              let response = try? JSONDecoder().decode(FollowerIDsResponse.self, from: data) else {
            app.logger.warning("CareEventConsumer: failed to fetch followers for user \(userID)")
            return []
        }
        return response.followerIDs
    }

    private func saveFeedPosts(payload: CareEventCreatedPayload, followerIDs: [UUID]) async {
        let db = app.db
        for followerID in followerIDs {
            let post = FeedPost(
                ownerUserID: followerID,
                authorUserID: payload.userId,
                plantID: payload.plantId,
                careEventID: payload.careEventId,
                kind: payload.kind,
                occurredAt: payload.occurredAt
            )
            do {
                try await post.save(on: db)
            } catch {
                app.logger.warning("CareEventConsumer: failed to save feed post for \(followerID): \(error)")
            }
        }
        app.logger.info("CareEventConsumer: created \(followerIDs.count) feed posts")
    }
}
