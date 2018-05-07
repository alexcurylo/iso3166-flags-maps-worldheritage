//
//  Utilities.swift
//  Masterlister
//
//  Created by Curylo, Alex (Agoda) on 7/5/18.
//  Copyright © 2018 Trollwerks Inc. All rights reserved.
//

import Foundation

#if !swift(>=4.1)
    public extension Sequence {
        func compactMap<T>(_ fn: (Element) throws -> T?) rethrows -> [T] {
            return try flatMap { try fn($0).map { [$0] } ?? [] }
        }
    }
#endif
