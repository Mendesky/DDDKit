@available(*, deprecated, message: "Using EvnetSourcingProjector insteads.")
public protocol Projector: AnyObject {
    associatedtype PresenterType: Presenter

    func find(byId id: String) async throws -> PresenterType.ReadModelType?
}
