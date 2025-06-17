//
//  JBEventBus.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/4/23.
//
import DDDCore
import KurrentDB

extension DomainEventBus{
    
    public func postEvent(event: RecordedEvent) async throws {
        notificationCenter.post(name: .init(event.eventType), object: event)
    }
    
    public func postEvent(event: ReadEvent) async throws {
        try await self.postEvent(event: event.record)
    }

    
    public func subscribe<EventType: DomainEvent>(to eventType: EventType.Type, handler: @escaping (_ event: EventType) -> Void) {
        let eventTypeString = "\(eventType)"
        
        notificationCenter.addObserver(forName: .init(eventTypeString), object: nil, queue: .main) { notification in
            do{
                let event = try (notification.object as? RecordedEvent).map{
                    try $0.decode(to: EventType.self)
                } ?? notification.object
                
                guard let event = event as? EventType else {
                    return
                }
                
                handler(event)
                
            }catch{
                logger.warning("[\(Self.self)] failed to decode event: \(error)")
            }
        }
    }
}
