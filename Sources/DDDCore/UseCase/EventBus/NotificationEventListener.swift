import Foundation

public protocol NotificationEventListener {
    associatedtype EventType: NotificationEvent

    func observed(event: EventType) async throws
}


extension DomainEventBus {
    public func register<Listener: NotificationEventListener>(listener: Listener) throws {
        try subscribe(to: Listener.EventType.self) { event in
            try await listener.observed(event: event)
        }
    }
}
