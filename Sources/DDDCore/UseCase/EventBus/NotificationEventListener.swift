import Foundation

public protocol NotificationEventListener {
    associatedtype EventType: NotificationEvent

    func observed(event: EventType) async throws
}
