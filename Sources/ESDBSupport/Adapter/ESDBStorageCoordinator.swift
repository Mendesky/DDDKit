import DDDCore
import EventSourcing
import KurrentDB
import Foundation
import Logging

fileprivate struct EventWrapped: Sendable{
    let event: any DomainEvent
    let revision: UInt64
}

public actor ESDBStorageCoordinator<ProjectableType: Projectable>: EventStorageCoordinator {
    let logger = Logger(label: "ESDBStorageCoordinator")
    let eventMapper: any EventTypeMapper
    let client: KurrentDBClient

    public init(client: KurrentDBClient, eventMapper: any EventTypeMapper) {
        self.eventMapper = eventMapper
        self.client = client
    }

    public func append(events: [any DDDCore.DomainEvent], byId id: ProjectableType.ID, version: UInt64?, external: [String:String]?) async throws -> UInt64? {
        let streamName = ProjectableType.getStreamName(id: id)
        let events = try events.map {
            let customMetadata = CustomMetadata(
                className: "\(type(of: $0))",
                external: external
            )
            let encoder = JSONEncoder()
            return try EventData(id: $0.id, eventType: $0.eventType, model: $0, customMetadata: encoder.encode(customMetadata))
        }
        let response = try await client.appendStream(.init(name: streamName), events: events){ options in
            guard let version else {
                return options.revision(expected: .any)
            }
            return options.revision(expected: .at(UInt64(version)))
        }

        return response.currentRevision.flatMap {
            .init($0)
        }
    }

    public func fetchEvents(byId id: ProjectableType.ID) async throws -> (events: [any DomainEvent], latestRevision: UInt64)? {
        
        let streamName = ProjectableType.getStreamName(id: id)
        do{
            let recordEvents:[RecordedEvent] = try await client.readStream(.init(name: streamName)){
                    $0.startFrom(revision: .start)
                      .resolveLinks()
            }.map { response in
                try response.event.record
            }.reduce(.init()) { partialResult, event in
                return partialResult + [event]
            }
            
            let eventWrappers: [EventWrapped] = recordEvents.reduce(into: .init()) {
                do{
                    guard let event = try self.eventMapper.mapping(eventData: $1) else {
                        return
                    }
                    $0.append(.init(event: event, revision: $1.revision))
                }catch {
                    logger.warning("skipped event cause error happened. error: \(error)")
                    return
                }
            }
            
            guard let latestRevision = eventWrappers.last?.revision else {
                return nil
            }
            
            let events = eventWrappers.map(\.event)
            let sortedEvents = events.sorted {
                $0.occurred < $1.occurred
            }
            
            return (events: sortedEvents, latestRevision: latestRevision)
        } catch KurrentError.resourceNotFound(let reason){
            logger.warning("Skip an error happened in esdb, with reason: \(reason)")
            return nil
        }catch{
            logger.error("The error happened when fetching events: \(error)")
            throw error
        }
    }
}
