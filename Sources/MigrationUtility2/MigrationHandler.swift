//
//  MigrationHandler.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/6/6.
//
import DDDCore
import KurrentDB


public protocol MigrationHandler: Sendable {
    associatedtype AggregateRootType: AggregateRoot
    associatedtype EventType: DomainEvent
    associatedtype UserInfoType: Sendable

    var action: @Sendable (AggregateRootType, EventType, UserInfoType) throws -> Void { get }
}

extension MigrationHandler {
    func decode(recordedEvent: RecordedEvent) throws -> EventType?{
        try recordedEvent.decode(to: EventType.self)
    }
    
    func handle(aggregateRoot: AggregateRootType, event: any DomainEvent, userInfo: UserInfoType) throws {
        guard let event = event as? EventType else {
            return
        }
        try self.action(aggregateRoot, event, userInfo)
    }
}

public protocol CreatedMigrationHandler: Sendable {
    associatedtype AggregateRootType: AggregateRoot
    associatedtype EventType: DomainEvent
    associatedtype UserInfoType: Sendable

    var action: @Sendable (EventType, UserInfoType) throws -> AggregateRootType? { get }
}
