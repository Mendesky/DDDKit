//
//  MigrationUtility.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/6/6.
//
import DDDCore

public actor MigrationBuilder<MigrationType: Migration>: Sendable {

    private var handlers: [any MigrationHandler]
    
    public init() {
        self.handlers = []
    }
    
    @discardableResult
    public func when<T: DomainEvent>(eventType: T.Type, action: @escaping @Sendable (_ aggregateRoot: MigrationType.AggregateRootType, _ event: T, _ userInfo: MigrationType.UserInfoType?) throws -> Void ) rethrows ->Self{
        let handler = EventTypeHandler<T, MigrationType.AggregateRootType, MigrationType.UserInfoType>(action: action)
        self.handlers.append(handler)
        return self
    }
    
    public func build(userInfo: MigrationType.UserInfoType) -> MigrationType{
        return MigrationType(handlers: handlers, userInfo: userInfo)
    }
}


public protocol Migration: Sendable {
    associatedtype AggregateRootType: AggregateRoot
    associatedtype UserInfoType
    
    var handlers: [any MigrationHandler] { get }
    var userInfo: UserInfoType? { get }
    
    init(handlers: [any MigrationHandler], userInfo: UserInfoType?)
}

extension Migration {
    
    public func migrate(events: [any DomainEvent]) throws -> AggregateRootType? {
        guard let createdEvent = events.first as? AggregateRootType.CreatedEventType else {
            return nil
        }
        
        guard let aggregateRoot = try AggregateRootType(first: createdEvent, other: []) else {
            return nil
        }
        
        try aggregateRoot.add(domainEvent: createdEvent)
        
        for event in events.filter({ $0.eventType != "\(AggregateRootType.CreatedEventType.self)" }) {
            var result: Bool = false
            for handler in handlers {
                let r = try handleEvent(aggregateRoot: aggregateRoot, handler: handler, event: event)
                if r {
                    result = r
                    break
                }
            }
            
            if !result {
                do{
                    try aggregateRoot.apply(event: event)
                }catch{
                    throw MigrationError.apply(error: error, event: event)
                }
                
                
            }
            
        }
        
        return aggregateRoot
    }
    
    func handleEvent<Handler: MigrationHandler>(aggregateRoot: AggregateRootType, handler: Handler, event: any DomainEvent) throws -> Bool {
        
        guard
            let userInfo = userInfo as? Handler.UserInfoType,
            let aggregateRoot = aggregateRoot as? Handler.AggregateRootType
        else {
            return false
        }
        
        guard let event = event as? Handler.EventType else {
            return false
        }
        do{
            try handler.handle(aggregateRoot: aggregateRoot, event: event, userInfo: userInfo)
        }catch{
            throw MigrationError.event(error: error, event: event)
        }
        
        return true
    }
}
