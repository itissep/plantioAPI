import Vapor

struct CareEventConsumerLifecycle: LifecycleHandler {
    func didBoot(_ application: Application) throws {
        let consumer = CareEventConsumer(app: application)
        Task {
            await consumer.start()
        }
    }
}
