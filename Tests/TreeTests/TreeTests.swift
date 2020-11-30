import XCTest
@testable import Tree

struct Pair<First, Second> {
    init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
    
    var first: First
    var second: Second
}

extension Pair: Equatable where First: Equatable, Second: Equatable {}
extension Pair: Hashable where First: Hashable, Second: Hashable {}

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
            tree.map(\.value),
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
        
        print(tree.endIndex)
        var index = tree.index(before: tree.endIndex)
        while index > tree.startIndex {
            print(index)
            print(tree[index].value)
            index = tree.index(before: index)
        }
        
        XCTAssertEqual(
            Array(tree.reversed()).count,
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"].count
        )
        
        XCTAssertEqual(
            Set(tree.reversed().map(\.value)),
            Set(["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"])
        )
        
        XCTAssertEqual(
            tree.reversed().map(\.value),
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"].reversed()
        )
    }
    
    func testTreeRootIndexAfter() {
        let tree: TreeList = [TreeNode(
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
            tree.map(\.value),
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"]
        )
    }
    func testTreeRootReveresed() {
        let tree: TreeList = [TreeNode(
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
            Set(tree.reversed().map(\.value)),
            Set(["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"])
        )
        
        XCTAssertEqual(
            tree.reversed().map(\.value),
            ["A", "AA", "AB", "AC", "ACA", "ACB", "ACC", "ACD", "ACDA", "ACDB", "ACDC", "AD"].reversed()
        )
    }
    
//    func testRemoveAll() {
//        var tree: TreeList = [TreeNode(
//            "A",
//            children: [
//                .init("AA"),
//                .init("AB"),
//                .init("AC", children: [
//                    .init("ACA"),
//                    .init("ACB"),
//                    .init("ACC"),
//                    .init("ACD", children: [
//                        .init("ACDA"),
//                        .init("ACDB"),
//                        .init("ACDC"),
//                    ]),
//                ]),
//                .init("AD"),
//        ])]
//        tree.removeAll()
//        XCTAssertEqual(tree.count, 0)
//    }
    func testInsert() {
        var tree = TreeList<String>()
        tree.insert(contentsOf: [TreeNode("A")], at: tree.startIndex)
        XCTAssertEqual(tree.map(\.value), ["A"])
    }
    func testInsertContentsOf() {
        var tree = TreeList<String>()
        tree.insert(contentsOf: ["A", "B", "C"].map{ TreeNode($0) }, at: tree.startIndex)
        XCTAssertEqual(tree.map(\.value), ["A", "B", "C"])
        XCTAssertEqual(tree, TreeList([.init("A"), .init("B"), .init("C")]))
        print(tree)
    }
    
    func testDiffing() {
        var tree: TreeList = [TreeNode(
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
        let tree1 = tree
        var tree2 = tree
        tree2.remove(at: tree.firstIndex(where: { $0.value == "AC" })!)
        XCTAssertEqual(
            tree2,
            [TreeNode(
                "A",
                children: [
                    .init("AA"),
                    .init("AB"),
                    .init("AD"),
            ])]
        )
    }
    func testMapChildrenWithParents() {
        let tree: TreeList = """
        - A
          - B
          - C
            - D
            - E
          - F
        """
        XCTAssertEqual(tree.mapChildrenWithParents({ Pair($0, $1) }), [
            Pair([], ["A"]),
            Pair(["A"], ["B", "C", "F"]),
            Pair(["A", "B"], []),
            Pair(["A", "C"], ["D", "E"]),
            Pair(["A", "C", "D"], []),
            Pair(["A", "C", "E"], []),
            Pair(["A", "F"], []),
        ])
    }
}
