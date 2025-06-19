import Foundation

public protocol DomainEventListener {
    associatedtype EventType: DomainEvent

    func observed(event: EventType)
}


extension DomainEventBus {
    public func register<Listener: DomainEventListener>(listener: Listener) throws {
        try subscribe(to: Listener.EventType.self) { event in
            listener.observed(event: event)
        }
    }
}
