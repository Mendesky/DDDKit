//
//  MigrationHandler.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/6/6.
//
import DDDCore

public protocol MigrationHandler: Sendable {
    associatedtype AggregateRootType: AggregateRoot
    associatedtype EventType: DomainEvent
    associatedtype UserInfoType: Sendable

    var action: @Sendable (AggregateRootType, EventType, UserInfoType) throws -> Void { get }
}


extension MigrationHandler {
    func handle(aggregateRoot: AggregateRootType, event: EventType, userInfo: UserInfoType) throws {
        try self.action(aggregateRoot, event, userInfo)
    }
}


public protocol CreatedEventHandler: Sendable {
    associatedtype AggregateRootType: AggregateRoot
    associatedtype EventType: DomainEvent
    associatedtype UserInfoType: Sendable

    var action: @Sendable (EventType, UserInfoType) throws -> AggregateRootType { get }
}

extension CreatedEventHandler {
    func handle(event: EventType, userInfo: UserInfoType) throws -> AggregateRootType {
        try self.action(event, userInfo)
    }
}
