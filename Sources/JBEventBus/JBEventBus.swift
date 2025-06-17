import DDDCore
import Foundation
import ESDBSupport

public class JBEventBus: DomainEventBus {
    public private(set) var notificationCenter: NotificationCenter = .default

    public func publish(event: some DomainEvent){
        notificationCenter.post(name: .init(event.eventType), object: event)
    }
    
    package func publish<Subscriber: EventSubscriber>(of subscriber: Subscriber, event: some DomainEvent) async throws {
        guard let event = event as? Subscriber.Event else {
            return
        }
        
        notificationCenter.post(name: .init(subscriber.eventName), object: event)
    }

    public init() {

    }
}
