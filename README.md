# DDDKit


### event
```
struct TestAggregateRootCreated: DomainEvent {
    var eventType: String = "TestAggregateRootCreated"
    var occurred: Date = .now
    var aggregateId: String
}

struct TestAggregateRootDeleted: DeletedEvent {
    var eventType: String = "TestAggregateRootDeleted"

    var occurred: Date = .now

    var aggregateId: String

    init(aggregateId: String) {
        self.aggregateId = aggregateId
    }

}
```

### AggregateRoot
```
class TestAggregateRoot: AggregateRoot {
    typealias CreatedEventType = TestAggregateRootCreated

    typealias DeletedEventType = TestAggregateRootDeleted

    typealias ID = String
    var id: String
    
    var metadata: DDDCore.AggregateRootMetadata = .init()

    init(id: String){
        self.id = id
        
        let event = TestAggregateRootCreated(aggregateId: id)
        try? self.apply(event: event)
    }

    required convenience init?(first firstEvent: TestAggregateRootCreated, other events: [any DDDCore.DomainEvent]) throws {
        self.init(id: firstEvent.aggregateId)
        try self.apply(events: events)
    }

    func when(happened event: some DDDCore.DomainEvent) throws {
        
    }

    
}
```

### Event Mapper
```
struct Mapper: EventTypeMapper {
    func mapping(eventData: EventStoreDB.RecordedEvent) throws -> (any DDDCore.DomainEvent)? {
        return switch eventData.eventType {
        case "TestAggregateRootCreated":
            try eventData.decode(to: TestAggregateRootCreated.self)
        case "TestAggregateRootDeleted":
            try eventData.decode(to: TestAggregateRootDeleted.self)
        default:
            nil
        }
    }
    
}
```

### Repository
```
class TestRepository: EventSourcingRepository {
    typealias AggregateRootType = TestAggregateRoot
    typealias StorageCoordinator = ESDBStorageCoordinator<TestAggregateRoot>

    var coordinator: StorageCoordinator

    init(client: EventStoreDBClient) {
        self.coordinator = .init(client: client, eventMapper: Mapper())
    }
}

```

### save aggregateRoot and find
```
let testId = "idForTesting"
let aggregateRoot = TestAggregateRoot(id: testId)
let repository = try TestRepository()

try await repository.save(aggregateRoot: aggregateRoot)

let finded = try await repository.find(byId: testId)
XCTAssertNotNil(finded)
```

### save aggregateRoot and deleted, should find a nil result
```
let testId = "idForTesting"
let aggregateRoot = TestAggregateRoot(id: testId)
let repository = try TestRepository()

try await repository.save(aggregateRoot: aggregateRoot)

try await repository.delete(byId: testId)

let finded = try await repository.find(byId: testId)
XCTAssertNil(finded)
```

### save aggregateRoot and deleted, should find a nil result with a `forcly` argument. 
```
let testId = "idForTesting"
let aggregateRoot = TestAggregateRoot(id: testId)
let repository = try TestRepository()

try await repository.save(aggregateRoot: aggregateRoot)

try await repository.delete(byId: testId)

let finded = try await repository.find(byId: testId, forcly: true)
XCTAssertNotNil(finded)
```
