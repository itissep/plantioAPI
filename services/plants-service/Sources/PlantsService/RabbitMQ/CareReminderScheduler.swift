import Foundation
import Vapor

struct CareReminderPayload: Codable {
    var event: String
    var plantId: UUID
    var userId: UUID
    var plantName: String
    var daysSinceLast: Int?
}

actor CareReminderChecker {
    private let app: Application
    private let exchange = "plants.events"
    private let routingKey = "care.reminder"
    private let checkInterval: UInt64 = 6 * 60 * 60 * 1_000_000_000 // 6 часов

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
        app.logger.info("CareReminderChecker: starting")
        while !Task.isCancelled {
            await checkPlants()
            try? await Task.sleep(nanoseconds: checkInterval)
        }
    }

    private func checkPlants() async {
        app.logger.info("CareReminderChecker: checking plants for overdue care")
        let db = app.db

        let plants: [Plant]
        do {
            plants = try await Plant.query(on: db)
                .filter(\.$wateringPeriod != nil)
                .all()
        } catch {
            app.logger.warning("CareReminderChecker: failed to query plants: \(error)")
            return
        }

        let now = Date()
        for plant in plants {
            guard let period = plant.wateringPeriod,
                  let plantID = plant.id else { continue }

            let lastWatering = try? await CareEvent.query(on: db)
                .filter(\.$plant.$id == plantID)
                .filter(\.$kind == "watering")
                .sort(\.$occurredAt, .descending)
                .first()

            let daysSinceLast: Int?
            let isOverdue: Bool

            if let last = lastWatering {
                let days = Int(now.timeIntervalSince(last.occurredAt) / 86400)
                daysSinceLast = days
                isOverdue = days >= period
            } else {
                daysSinceLast = nil
                isOverdue = true
            }

            if isOverdue {
                await publishReminder(plant: plant, daysSinceLast: daysSinceLast)
            }
        }
    }

    private func publishReminder(plant: Plant, daysSinceLast: Int?) async {
        guard let plantID = plant.id else { return }

        let payload = CareReminderPayload(
            event: "CareReminder",
            plantId: plantID,
            userId: plant.userID,
            plantName: plant.name,
            daysSinceLast: daysSinceLast
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let payloadData = try? encoder.encode(payload),
              let payloadStr = String(data: payloadData, encoding: .utf8) else { return }

        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .authorization, value: basicAuth)
        headers.replaceOrAdd(name: .contentType, value: "application/json")

        let body = """
        {"properties":{},"routing_key":"\(routingKey)","payload":"\(payloadStr.replacingOccurrences(of: "\"", with: "\\\""))","payload_encoding":"string"}
        """

        let uri = URI(string: "http://\(host):\(managementPort)/api/exchanges/\(vhostEncoded)/\(exchange)/publish")
        var req = ClientRequest(method: .POST, url: uri, headers: headers)
        req.body = ByteBuffer(string: body)

        do {
            _ = try await app.client.send(req)
            app.logger.info("CareReminderChecker: published reminder for plant \(plant.name)")
        } catch {
            app.logger.warning("CareReminderChecker: failed to publish reminder: \(error)")
        }
    }
}

struct CareReminderSchedulerLifecycle: LifecycleHandler {
    func didBoot(_ application: Application) throws {
        let checker = CareReminderChecker(app: application)
        Task {
            await checker.start()
        }
    }
}
