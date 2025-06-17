import Foundation

public protocol DomainEventBus {
    
    var notificationCenter: NotificationCenter { get }
    
    func publish<EventType: DomainEvent>(event: EventType) async throws
    func subscribe<EventType: DomainEvent>(to eventType: EventType.Type, handler: @escaping (_ event: EventType) -> Void)
}

extension DomainEventBus {
    public func postAllEvent(fromAggregateRoot aggregateRoot: some AggregateRoot) async throws {
        for event in aggregateRoot.events {
            try await publish(event: event)
        }
    }
}
