import Foundation

public protocol AggregateRoot: Projectable, Entity {
    associatedtype CreatedEventType: DomainEvent
    associatedtype DeletedEventType: DeletedEvent

    var metadata: AggregateRootMetadata { get }

    init?(events: [any DomainEvent]) async throws
    init?(first createdEvent: CreatedEventType, other events: [any DomainEvent]) async throws

    func add(domainEvent: some DomainEvent) async throws
    func when(happened event: some DomainEvent) throws
    func ensureInvariant() throws
}

extension AggregateRoot {
    public init?(events: [any DomainEvent]) async throws {
        var events = events
        guard let createdEvent = events.removeFirst() as? CreatedEventType else {
            return nil
        }

        try await self.init(first: createdEvent, other: events)
    }
    
    public var deleted: Bool {
        get async{
            await metadata.deleted
        }
    }

    public var events: [any DomainEvent] {
        get async {
            await metadata.events
        }
    }

    public var version: UInt64? {
        get async {
            await metadata.version
        }
    }

    public func apply(event: some DomainEvent) async throws {
        let deleted = await metadata.deleted
        guard !deleted else {
            throw DDDError.operationNotAllow(operation: "apply", reason: "the aggregate root `\(Self.self)(\(id))` is deleted.", userInfos: ["event": event, "aggregateRootType": "\(Self.self)", "aggregateRootId": id])
        }
        try ensureInvariant()
        try when(happened: event)
        try ensureInvariant()
        try await add(domainEvent: event)
    }

    public func apply(events: [any DomainEvent]) async throws {
        for event in events {
            try await apply(event: event)
        }
    }

    public func add(domainEvent: some DomainEvent) async  throws {
        await metadata.apppend(event: domainEvent)
    }

    public func clearAllDomainEvents() async throws {
        await metadata.removeAll()
    }

    public func ensureInvariant() throws {}
}
