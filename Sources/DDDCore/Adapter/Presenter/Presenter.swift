import Foundation

@available(*, deprecated, message: "Using EvnetSourcingPresenter insteads.")
public protocol Presenter: Projectable {
    associatedtype ReadModelType: ReadModel
    
    func buildReadModel(events: [any DomainEvent]) async throws -> PresenterOutput<ReadModelType>
}
