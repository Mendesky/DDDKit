import Foundation
import DDDCore

public protocol Presenter {
    associatedtype ReadModelType: ReadModel
    func buildReadModel(events: [any DomainEvent]) async throws -> PresenterOutput<ReadModelType>
}
