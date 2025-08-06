//
//  IdGenerator.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/8/7.
//

import Foundation
import KurrentDB


public actor TestBundle {
    public let client: KurrentDBClient
    public var streamIdentifiers: [StreamIdentifier] = []
    public let cleanPhase: CleanPhase
    
    fileprivate init(client: KurrentDBClient, cleanPhase: TestBundle.CleanPhase) {
        self.client = client
        self.streamIdentifiers = []
        self.cleanPhase = cleanPhase
    }
    
    public func generateId(for category: String) async -> String {
        let id = UUID().uuidString
        let streamIdentifier = StreamIdentifier(name: "\(category)-\(id)")
        self.streamIdentifiers.append(streamIdentifier)
        
        if cleanPhase.containsBegin {
            await self.clearStream(streamIdentifier: streamIdentifier)
        }
        
        return id
    }
    
    fileprivate func clearStream(streamIdentifier: StreamIdentifier) async {
        _ = try? await self.client.deleteStream(streamIdentifier){ options in
            options.revision(expected: .any)
        }
    }
    
    public func clearStreams() async {
        await withTaskGroup { group in
            for streamIdentifier in self.streamIdentifiers {
                group.addTask { [unowned self] in
                    await self.clearStream(streamIdentifier: streamIdentifier)
                }
            }
        }
        
    }
    
}

extension TestBundle {
    public enum CleanPhase{
        case none
        case begin
        case end
        case both
        
        fileprivate var containsBegin: Bool {
            switch self {
            case .none, .end:
                return false
            case .begin, .both:
                return true
            }
        }
        
        fileprivate var containsEnd: Bool {
            switch self {
            case .end, .both:
                return true
            case .none, .begin:
                return false
            }
        }
    }
}


public func withTestBundle(client: KurrentDBClient, cleanPhase: TestBundle.CleanPhase = .both, action: (_ bundle: TestBundle) async throws -> Void ) async throws {
    let bundle = TestBundle(client: client, cleanPhase: cleanPhase)
    do{
        try await action(bundle)
    }catch{
        print("Test failed with error: \(error)")
    }
    
    if cleanPhase.containsEnd {
        await bundle.clearStreams()
    }
}


