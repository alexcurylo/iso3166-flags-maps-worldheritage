// @copyright Trollwerks Inc.

import Foundation

#if !swift(>=4.1)
    public extension Sequence {
        func compactMap<T>(_ fn: (Element) throws -> T?) rethrows -> [T] {
            return try flatMap { try fn($0).map { [$0] } ?? [] }
        }
    }
#endif
