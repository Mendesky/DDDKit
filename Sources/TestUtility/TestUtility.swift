//
//  TestUtility.swift
//  
//
//  Created by Grady Zhuo on 2024/6/13.
//

import DDDCore
import EventStoreDB
import Logging

let logger = Logger(label: "TestUtility")

extension EventStoreDBClient {
    public func clearStreams<T: AggregateRoot>(aggregateRootType: T.Type, id: T.ID, errorHandler: ((_ error: Error)->Void)? = nil) async {
        do{
            let streamIdentifier: Stream.Identifier = .init(name: T.getStreamName(id: id))
            try await self.deleteStream(to: streamIdentifier) { options in
                options.revision(expected: .streamExists)
            }
        }catch {
            logger.warning("The error happended when clear stream with \(id) in \(aggregateRootType). error message: \(error)")
            errorHandler?(error)
        }
    }

    public func clearStreams<T: Projectable>(projectableType: T.Type, streamName: String, errorHandler: ((_ error: Error)->Void)? = nil) async {
        do{
            let streamIdentifier: Stream.Identifier = .init(name: streamName)
            try await self.deleteStream(to: streamIdentifier) { options in
                options.revision(expected: .streamExists)
            }
        }catch {
            logger.warning("The error happended when clear stream with \(streamName) in \(projectableType). error message: \(error)")
            errorHandler?(error)
        }
    }
}


