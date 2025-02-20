//
//  EventMapperGenerator.swift
//  
//
//  Created by 卓俊諺 on 2025/2/11.
//

import Foundation
import Yams

package struct EventMapperGenerator {
    let modelName: String
    let eventNames: [String]
    
    package init(modelName: String, eventNames: [String]) {
        self.modelName = modelName
        self.eventNames = eventNames
    }
    
    package func render(accessLevel: AccessLevel)-> [String] {
        var lines: [String] = []
        
        lines.append("""
\(accessLevel.rawValue) struct \(modelName)EventMapper: EventTypeMapper {

    \(accessLevel.rawValue) init(){}

    \(accessLevel.rawValue) func mapping(eventData: RecordedEvent) throws -> (any DomainEvent)? {
""")
        
        lines.append("""
        return switch eventData.mappingClassName {
""")
        
        for eventName in eventNames {
            lines.append("""
        case "\\(\(eventName).self)":
            try eventData.decode(to: \(eventName).self)
""")
        }
        
        lines.append("""
        default:
            nil
""")
        
        lines.append("""
        }
    }
}
""")
        return lines
    }
}
