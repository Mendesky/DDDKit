//
//  Entity.swift
//
//
//  Created by Grady Zhuo on 2024/5/26.
//

import Foundation

public protocol Entity: Actor, Sendable {
    associatedtype ID: Hashable, Sendable
    
    var id: ID { get }
}
