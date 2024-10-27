import DDDCore
import EventSourcing
import EventStoreDB
import Foundation

public class ESDBStorageCoordinator<ProjectableType: Projectable>: EventStorageCoordinator {
    let eventMapper: any EventTypeMapper
    let client: EventStoreDBClient

    public init(client: EventStoreDBClient, eventMapper: any EventTypeMapper) {
        self.eventMapper = eventMapper
        self.client = client
    }

    public func append(events: [any DDDCore.DomainEvent], byId id: ProjectableType.ID, version: UInt?) async throws -> UInt? {
        let streamName = ProjectableType.getStreamName(id: id)
        let events = try events.map {
            try EventData(id: $0.id, eventType: $0.eventType, payload: $0)
        }

        let response = try await client.appendStream(to: .init(name: streamName), events: events) { options in
            guard let version else {
                return options.revision(expected: .any)
            }
            return options.revision(expected: .revision(UInt64(version)))
        }

        return response.current.revision.flatMap {
            .init($0)
        }
    }

    public func fetchEvents(byId id: ProjectableType.ID) async throws -> (events: [any DomainEvent]?, latestRevision: UInt?) {
        let streamName = ProjectableType.getStreamName(id: id)
        do{
            let responses = try client.readStream(to: .init(name: streamName), cursor: .start) { options in
                options.set(resolveLinks: true)
            }

            let events: [any DomainEvent]? = try await responses.reduce(into: nil) {
                guard case let .event(readEvent) = $1.content else {
                    return
                }
                
                guard let event = try self.eventMapper.mapping(eventData: readEvent.recordedEvent) else {
                    return
                }

                if $0 == nil {
                    $0 = .init()
                }
                $0?.append(event)
            }
            return (events: events, latestRevision: nil)
            
        }catch ClientError.streamNotFound(let message){
            print("ESDBError streamNotFound: \(message)")
            return (events: nil, latestRevision: nil)
        }catch {
            throw error
        }
    }
}
