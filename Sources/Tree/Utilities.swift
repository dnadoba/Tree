//
//  Utilities.swift
//  
//
//  Created by David Nadoba on 07.12.20.
//

import Foundation

extension BidirectionalCollection {
    @inlinable
    internal subscript(safe i: Index) -> Element? {
        guard indices.contains(i) else { return nil }
        return self[i]
    }
}
