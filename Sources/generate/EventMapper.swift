//
//  EventMapper.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/2/15.
//

import Yams
import Foundation
import ArgumentParser
import DomainEventGenerator

struct GenerateEventMapperCommand: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "event-mapper",
        abstract: "Generate event-mapper swift files.")
    
    @Argument(help: "The path of the event file.", completion: .file(extensions: ["yaml", "yam"]))
    var eventDefinitionPath: String
    
    @Argument(help: "The path of the projection-model file.", completion: .file(extensions: ["yaml", "yam"]))
    var projectionModelDefinitionPath: String
    
    @Option(completion: .file(extensions: ["yaml", "yam"]), transform: {
        let url = URL(fileURLWithPath: $0)
        let yamlData = try Data(contentsOf: url)
        let yamlDecoder = YAMLDecoder()
        return try yamlDecoder.decode(GeneratorConfiguration.self, from: yamlData)
    })
    var configuration: GeneratorConfiguration
    
    @Option
    var inputType: InputType = .yaml
    
    @Option
    var defaultAggregateRootName: String
    
    @Option
    var accessModifier: AccessLevel?
    
    @Option(name: .shortAndLong, help: "The path of the generated swift file")
    var output: String? = nil
    
    func run() throws {
        let aggregateRootName = configuration.aggregateRootName ?? defaultAggregateRootName
        
        let projectionModelGenerator = try ProjectionModelGenerator(projectionModelYamlFileURL: .init(filePath: projectionModelDefinitionPath), aggregateRootName: aggregateRootName, aggregateEventsYamlFileURL: .init(filePath: eventDefinitionPath))
        
        guard let outputPath = output else {
            throw GenerateCommand.Errors.outputPathMissing
        }
        
        let accessModifier = accessModifier ?? configuration.accessModifier
        
        let defaultDependencies = ["Foundation", "DDDCore", "ESDBSupport", "KurrentDB"]
        let configDependencies = configuration.dependencies ?? []
        let headerGenerator = HeaderGenerator(dependencies: defaultDependencies + configDependencies)

        var lines: [String] = []
        lines.append(contentsOf: headerGenerator.render())
        lines.append("")
        
        for (modelName, projectionModelDefinition) in projectionModelGenerator.definitions {
            var eventNames = projectionModelDefinition.events
            eventNames.append(projectionModelDefinition.createdEvent)
            if let deletedEvent = projectionModelDefinition.deletedEvent {
                eventNames.append(deletedEvent)
            }
            let eventMapperGenerator = EventMapperGenerator(modelName: modelName, eventNames: eventNames)
            lines.append(contentsOf: eventMapperGenerator.render(accessLevel: accessModifier))
            lines.append("")
        }
        
        let content = lines.joined(separator: "\n")
        try content.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }
    
}
