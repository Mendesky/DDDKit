//
//  EventStructureGenerator.swift
//  
//
//  Created by 卓俊諺 on 2025/2/11.
//
import DDDCore

package struct EventStructureGenerator {
    var superProtocols: [String]
    let eventName: String
    let definition: EventDefinition
    
    init(eventName: String, definition: EventDefinition) {
        self.eventName = eventName
        self.definition = definition
        self.superProtocols = [definition.kind.protocol]
    }
    
    func render(accessLevel: AccessLevel, indentationCount: Int = 4)-> [String] {
        let indentation = String(repeating: " ", count: indentationCount)
        
        let properties: [PropertyDefinition] = [
            .init(name: "id", type: .uuid, default: ".init()"),
            .init(name: definition.aggregateRootId.alias, type: .string)
        ] + (definition.properties ?? []) + [
            .init(name: "occurred", type: .date, default: ".now")
        ]
        
        var lines: [String] = []
        let superProtocolsString = superProtocols.joined(separator: ", ")
        if definition.deprecated != nil {
            lines.append("""
@available(*, deprecated, message: "The struct type of event \(eventName) is deprecated.")
""")
        }
        
        lines.append("\(accessLevel.rawValue) struct \(eventName): \(superProtocolsString) {")
        properties.forEach {
            let generator = PropertyGenerator(definition: $0)
            lines.append("\(indentation)\(generator.render(accessLevel: accessLevel))")
        }
        
        lines.append("")
        let initArguments = properties.reduce([String]()) { partialResult, property in
            let generator = ArgumentGenerator(definition: property)
            return partialResult + [generator.render()]
        }
        let initArgumentsString = initArguments.joined(separator: ", \n\(indentation)\(indentation)\(indentation)\(indentation)  ")
        
        lines.append("\(indentation)\(accessLevel.rawValue) init(\(initArgumentsString)){")
        properties.forEach {
            let expression = "self.\($0.name) = \($0.name)"
            lines.append("\(indentation)\(indentation)\(expression)")
        }
        lines.append("\(indentation)}")
        lines.append("}")
        return lines
    }
}
