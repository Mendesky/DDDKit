//
//  Notification.swift
//  DDDKit
//
//  Created by Grady Zhuo on 2025/6/17.
//

import Foundation
public protocol NotificationEvent: Sendable, Codable {
    var occurred: Date { get }
}

