//
//  MigrationUtility.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/6/6.
//
import DDDCore
import EventSourcing
import ESDBSupport
import KurrentDB
import Foundation

public actor MigrationBuilder<MigrationType: Migration>: Sendable {

    private var createdHandler: (any CreatedMigrationHandler)?
    private var handlers: [any MigrationHandler]
    
    public init() {
        self.handlers = []
    }
    
    @discardableResult
    public func `init`<T: DomainEvent>(created eventType: T.Type, action: @escaping @Sendable (_ event: T, _ userInfo: MigrationType.UserInfoType?) throws -> MigrationType.AggregateRootType ) rethrows ->Self{
        let handler = CreatedEventMigrater<T, MigrationType.AggregateRootType, MigrationType.UserInfoType>(action: action)
        self.createdHandler = handler
        return self
    }
    
    @discardableResult
    public func when<T: DomainEvent>(eventType: T.Type, action: @escaping @Sendable (_ aggregateRoot: MigrationType.AggregateRootType, _ event: T, _ userInfo: MigrationType.UserInfoType?) throws -> Void ) rethrows ->Self{
        let handler = EventTypeHandler<T, MigrationType.AggregateRootType, MigrationType.UserInfoType>(action: action)
        self.handlers.append(handler)
        return self
    }
    
    @discardableResult
    public func `else`(action: @escaping @Sendable (_ aggregateRoot: MigrationType.AggregateRootType, _ event: any DomainEvent, _ userInfo: MigrationType.UserInfoType?) throws -> Void ) rethrows ->Self{
        let handler = EventTypeHandler<AnyDomainEvent, MigrationType.AggregateRootType, MigrationType.UserInfoType>(action: action)
        self.handlers.append(handler)
        return self
    }
    
    public func build(eventMapper: EventTypeMapper, userInfo: MigrationType.UserInfoType) -> MigrationType{
        return MigrationType(eventMapper: eventMapper, handlers: handlers, userInfo: userInfo)
    }
}



public final class OverlookCreatedMigrationHandler<AggregateRootType: AggregateRoot, UserInfoType: Sendable> : CreatedMigrationHandler {
    public let action: @Sendable (AggregateRootType.CreatedEventType, UserInfoType) throws -> AggregateRootType?
    
    public init() {
        self.action = { _, _ in nil }
    }
}

public protocol Migration: Sendable {
    associatedtype AggregateRootType: AggregateRoot
    associatedtype UserInfoType
    associatedtype CreatedHandler: CreatedMigrationHandler where CreatedHandler.AggregateRootType == AggregateRootType, CreatedHandler.UserInfoType == UserInfoType
    
    var eventMapper: EventTypeMapper { get }
    var createdHandler: CreatedHandler { get }
    var handlers: [any MigrationHandler] { get }
    var userInfo: UserInfoType? { get }
    
    init(eventMapper: EventTypeMapper, handlers: [any MigrationHandler], userInfo: UserInfoType?)
}

extension Migration {
    
    public func migrate(records: [RecordedEvent]) throws -> AggregateRootType? {
        
        guard let createdRecordedEvent = records.first else {
            return nil
        }
        
        guard let aggregateRoot = try initAggregateRoot(recorded: createdRecordedEvent) else {
            return nil
        }
        
        let records = records.dropFirst()
        
        for record in records {
            var handled: Bool = false
            for handler in self.handlers {
                guard let event = try handler.decode(recordedEvent: record)  else {
                    continue
                }
                let result = try handleEvent(aggregateRoot: aggregateRoot, handler: handler, event: event)
                if result {
                    handled = result
                    break
                }
            }
            
            if !handled {
                guard let event = try eventMapper.mapping(eventData: record) else {
                    break
                }
                try aggregateRoot.apply(event: event)
            }
        }
        return aggregateRoot
    }
    
    public func initAggregateRoot(recorded: RecordedEvent) throws -> AggregateRootType? {
        guard let oldEvent = try recorded.decode(to: CreatedHandler.EventType.self) else {
            return nil
        }
        
        guard let userInfo else {
            return nil
        }
        return try createdHandler.action(oldEvent, userInfo)
    }
    
    public func initAggregateRoot(recorded: RecordedEvent) throws -> AggregateRootType? where CreatedHandler == OverlookCreatedMigrationHandler<AggregateRootType, UserInfoType>{
        guard let createdEvent = try eventMapper.mapping(eventData: recorded) as? AggregateRootType.CreatedEventType else {
            return nil
        }
        return try .init(first: createdEvent, other: [])
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
