import XCTest
@testable import Tree

final class TreeTests: XCTestCase {
    func testIndexAfter() {
        let tree = TreeNode(
            "A",
            children: [
                .init("AA"),
                .init("AB"),
                .init("AC", children: [
                    .init("ACA"),
                    .init("ACB"),
                    .init("ACC"),
                    .init("ACD", children: [
                        .init("ACDA"),
                        .init("ACDB"),
                        .init("ACDC"),
                    ]),
                ]),
                .init("AD"),
        ])
        
        XCTAssertEqual(
            Array(tree),
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"]
        )
    }
    func testReveresed() {
        let tree = TreeNode(
            "A",
            children: [
                .init("AA"),
                .init("AB"),
                .init("AC", children: [
                    .init("ACA"),
                    .init("ACB"),
                    .init("ACC"),
                    .init("ACD", children: [
                        .init("ACDA"),
                        .init("ACDB"),
                        .init("ACDC"),
                    ]),
                ]),
                .init("AD"),
        ])
        
        XCTAssertEqual(
            Array(tree.reversed()).count,
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"].count
        )
        
        XCTAssertEqual(
            Set(tree.reversed()),
            Set(["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"])
        )
        
        XCTAssertEqual(
            Array(tree.reversed()),
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"].reversed()
        )
    }
    
    func testTreeRootIndexAfter() {
        let tree: TreeRoot = [TreeNode(
            "A",
            children: [
                .init("AA"),
                .init("AB"),
                .init("AC", children: [
                    .init("ACA"),
                    .init("ACB"),
                    .init("ACC"),
                    .init("ACD", children: [
                        .init("ACDA"),
                        .init("ACDB"),
                        .init("ACDC"),
                    ]),
                ]),
                .init("AD"),
        ])]
        
        XCTAssertEqual(
            Array(tree),
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"]
        )
    }
    func testTreeRootReveresed() {
        let tree: TreeRoot = [TreeNode(
            "A",
            children: [
                .init("AA"),
                .init("AB"),
                .init("AC", children: [
                    .init("ACA"),
                    .init("ACB"),
                    .init("ACC"),
                    .init("ACD", children: [
                        .init("ACDA"),
                        .init("ACDB"),
                        .init("ACDC"),
                    ]),
                ]),
                .init("AD"),
        ])]
        
        XCTAssertEqual(
            Array(tree.reversed()).count,
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"].count
        )
        
        XCTAssertEqual(
            Set(tree.reversed()),
            Set(["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"])
        )
        
        XCTAssertEqual(
            Array(tree.reversed()),
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"].reversed()
        )
    }
    
    func testRemoveAll() {
        var tree: TreeRoot = [TreeNode(
            "A",
            children: [
                .init("AA"),
                .init("AB"),
                .init("AC", children: [
                    .init("ACA"),
                    .init("ACB"),
                    .init("ACC"),
                    .init("ACD", children: [
                        .init("ACDA"),
                        .init("ACDB"),
                        .init("ACDC"),
                    ]),
                ]),
                .init("AD"),
        ])]
        tree.removeAll()
        XCTAssertEqual(tree.count, 0)
    }
    func testInsert() {
        var tree = TreeRoot<String>()
        tree.insert("A", at: tree.startIndex)
        XCTAssertEqual(Array(tree), ["A"])
    }
    func testInsertContentsOf() {
        var tree = TreeRoot<String>()
        tree.insert(contentsOf: ["A", "B", "C"], at: tree.startIndex)
        XCTAssertEqual(Array(tree), ["A", "B", "C"])
        XCTAssertEqual(tree, TreeRoot([.init("A"), .init("B"), .init("C")]))
        print(tree)
    }
}
