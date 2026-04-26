import Foundation
import NIOCore
import Vapor

struct CareEventCreatedPayload: Codable {
    var event: String
    var careEventId: UUID
    var plantId: UUID
    var userId: UUID
    var kind: String
    var occurredAt: Date
}

protocol CareEventNotifier {
    func publishCareEventCreated(_ payload: CareEventCreatedPayload, client: Client, logger: Logger) async
}

private struct ManagementPublishRequest: Encodable {
    var properties: [String: String] = [:]
    var routing_key: String
    var payload: String
    var payload_encoding: String = "string"
}

/// Публикует в topic exchange `plants.events` через HTTP API RabbitMQ Management (:15672).
struct RabbitMQManagementNotifier: CareEventNotifier {
    func publishCareEventCreated(_ payload: CareEventCreatedPayload, client: Client, logger: Logger) async {
        let host = Environment.get("RABBITMQ_HOST") ?? "rabbitmq"
        let user = Environment.get("RABBITMQ_USER") ?? "guest"
        let password = Environment.get("RABBITMQ_PASSWORD") ?? "guest"
        let vhostRaw = Environment.get("RABBITMQ_VHOST") ?? "/"
        let vhostEncoded: String = {
            if vhostRaw == "/" { return "%2F" }
            return vhostRaw.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? vhostRaw
        }()
        let managementPort = Environment.get("RABBITMQ_MANAGEMENT_PORT") ?? "15672"
        let exchange = "plants.events"
        let routingKey = "care_event.created"

        var basic = HTTPHeaders()
        let token = Data("\(user):\(password)".utf8).base64EncodedString()
        basic.replaceOrAdd(name: .authorization, value: "Basic \(token)")

        do {
            let putURI = URI(string: "http://\(host):\(managementPort)/api/exchanges/\(vhostEncoded)/\(exchange)")
            var putReq = ClientRequest(method: .PUT, url: putURI, headers: basic)
            putReq.headers.replaceOrAdd(name: .contentType, value: HTTPMediaType.json.serialize())
            var putBody = ByteBufferAllocator().buffer(string: #"{"type":"topic","durable":true}"#)
            putReq.body = putBody
            _ = try await client.send(putReq)
        } catch {
            logger.warning("RabbitMQ: declare exchange: \(error)")
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let innerData = try encoder.encode(payload)
            let innerStr = String(data: innerData, encoding: .utf8) ?? "{}"
            let pub = ManagementPublishRequest(routing_key: routingKey, payload: innerStr)
            var pubData = try JSONEncoder().encode(pub)
            let postURI = URI(
                string: "http://\(host):\(managementPort)/api/exchanges/\(vhostEncoded)/\(exchange)/publish"
            )
            var postReq = ClientRequest(method: .POST, url: postURI, headers: basic)
            postReq.headers.replaceOrAdd(name: .contentType, value: HTTPMediaType.json.serialize())
            var postBody = ByteBufferAllocator().buffer(capacity: pubData.count)
            postBody.writeBytes(pubData)
            postReq.body = postBody
            let res = try await client.send(postReq)
            if res.status != HTTPStatus.ok {
                logger.warning("RabbitMQ publish HTTP \(res.status)")
            }
        } catch {
            logger.warning("RabbitMQ publish failed (best-effort): \(error)")
        }
    }
}

struct NoOpCareEventNotifier: CareEventNotifier {
    func publishCareEventCreated(_ payload: CareEventCreatedPayload, client: Client, logger: Logger) async {}
}
