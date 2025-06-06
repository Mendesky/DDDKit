//
//  EventTypeHandler.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/6/6.
//
import DDDCore

public struct EventTypeHandler<EventType: DomainEvent, AggregateRootType: AggregateRoot, UserInfoType>: MigrationHandler{
    public var action: @Sendable (AggregateRootType, EventType, UserInfoType) throws -> Void
    
    init(action: @escaping @Sendable (AggregateRootType, EventType, UserInfoType) throws -> Void) {
        self.action = action
    }
}
