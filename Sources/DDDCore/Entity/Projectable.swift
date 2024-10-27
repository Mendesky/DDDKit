public protocol Projectable {

    associatedtype ID: Hashable
    
    static var category: String { get }
    
    var id: ID { get }
    init?(events: [any DomainEvent]) throws
    func when(happened event: some DomainEvent) throws
    func ensureInvariant() throws
}

extension Projectable {
    public static var category: String {
        "\(Self.self)"
    }

    public static func getStreamName(id: ID) -> String {
        "\(category)-\(id)"
    }
}
