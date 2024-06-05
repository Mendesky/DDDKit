//
//  File.swift
//  
//
//  Created by Grady Zhuo on 2024/6/6.
//

import Foundation
import EventStoreDB
import DDDCore

public protocol EventTypeMapper {
    func mapping(eventData: RecordedEvent) throws -> (any DomainEvent)?
}

