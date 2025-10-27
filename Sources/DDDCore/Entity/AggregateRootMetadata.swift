//
//  AggregateRootMetadata.swift
//
//
//  Created by Grady Zhuo on 2024/6/4.
//

import Foundation

public actor AggregateRootMetadata {
    var events: [any DomainEvent] = []

    public package(set) var deleted: Bool
    public package(set) var version: UInt64?

    public init() {
        deleted = false
        version = nil
    }
    
    public func delete() {
        self.deleted = true
    }
    
    public func update(version: UInt64){
        self.version = version
    }
    

    public func apppend(event: any DomainEvent){
        self.events.append(event)
    }
    
    public func removeAll(){
        self.events.removeAll()
    }
}
