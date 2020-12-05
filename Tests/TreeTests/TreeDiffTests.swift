//
//  File.swift
//  
//
//  Created by David Nadoba on 26.11.20.
//

import Foundation
import XCTest
@testable import Tree

extension TreeIndex {
    var depth: Int { indices.count - 1}
}

extension TreeList {
    func parentIndex(of i: TreeIndex, nthParent: Int = 1) -> TreeIndex {
        TreeIndex(indices: i.indices.dropLast(nthParent))
    }
    func indexInParent(after i: TreeIndex) -> TreeIndex {
        var indices = i.indices
        indices[indices.index(before: indices.endIndex)] += 1
        return TreeIndex(indices: indices)
    }
}

extension TreeList where Value == String {
    init(parse string: String) {
        var tree = TreeList<Value>()
        for line in string.split(separator: "\n") {
            guard let firstNonemptyIndex = line.firstIndex(where: { $0 != " " }) else {
                continue
            }
            guard let lastEmptyIndex = line.lastIndex(of: " ") else {
                continue
            }
            let value = String(line[line.index(after: lastEmptyIndex)...])
            
            let newDepth = line[..<firstNonemptyIndex].count / 2
            
            let lastIndex: TreeIndex = {
                if tree.isEmpty {
                    return TreeIndex(indices: [-1])
                } else {
                    return tree.index(before: tree.endIndex)
                }
            }()
            let insertIndex: TreeIndex = {
                let currentDepth = lastIndex.depth
                if currentDepth < newDepth {
                    return tree.addChildIndex(0, to: lastIndex)
                } else if currentDepth > newDepth {
                    return tree.indexInParent(after: tree.parentIndex(of: lastIndex, nthParent: currentDepth - newDepth))
                } else {
                    return tree.indexInParent(after: lastIndex)
                }
            }()
            tree.insert(.init(value), at: insertIndex)
        }
        self = tree
    }
}

extension TreeList: ExpressibleByStringLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral where Value == String {
    public typealias ExtendedGraphemeClusterLiteralType = String.ExtendedGraphemeClusterLiteralType
    public typealias UnicodeScalarLiteralType = String.UnicodeScalarLiteralType
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        self.init(parse: value)
    }
}


final class TreeDiffTests: XCTestCase {
    func calculateAndApplyDifference(
        _ tree1: TreeList<String>,
        _ tree2: TreeList<String>,
        debugPrint: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let diff = tree2.difference(from: tree1)
        if debugPrint {
            for change in diff.changes {
                print(change)
            }
            print("")
        }
        let diffWithMovements = diff.inferringMoves()
        if debugPrint {
            for change in diffWithMovements.changes {
                print(change)
            }
            print("")
        }
        XCTAssertEqual(tree1.applying(diffWithMovements), tree2, file: file, line: line)
    }
    func testTreeDiff() {
        calculateAndApplyDifference("""
        - A
          - B
          - C
            - D
            - E
          - F
        """,
        """
        - A
          - B
          - F
            - C
              - D
          - G
        """
        )
        
    }
    func testEmpty() {
        calculateAndApplyDifference(
            .init(),
            """
            - A
              - B
              - F
                - C
                  - D
              - G
            """
        )
    }
    func test1() {
        calculateAndApplyDifference("""
            - A
              - AA
              - ACA
              - ACC
              - AB
              - ACB
              - AC
                - ACD
                  - ACDB
                  - ACDC
              - ACDA
              - AD
            """,
            """
            - A
              - AA
              - ACA
              - ACB
              - ACC
              - AB
              - AC
                - ACD
                  - ACDA
                  - ACDB
                  - ACDC
              - AD
            """)
    }
    func test2() {
        calculateAndApplyDifference("""
            - A
              - AA
              - AB
              - AC
                - ACA
                - ACB
                - ACC
                - ACD
                  - ACDA
                  - ACDB
                  - ACDC
              - AD
            """, """
            - A
              - AA
              - AB
              - AC
                - ACA
                - ACB
                - ACD
                  - ACDA
                  - ACDB
                  - ACDC
                - ACC
              - AD
            """)
    }
    func test3() {
        calculateAndApplyDifference("""
         - A
           - AC
             - ACA
             - ACB
             - ACC
             - ACD
               - ACDA
               - ACDB
               - ACDC
           - AA
           - AB
           - AD
        """, """
        - AC
            - ACA
            - ACB
            - ACC
            - ACD
            - ACDA
            - ACDB
            - ACDC
        - AA
        - A
            - AB
            - AD
        """
        )
    }
}
