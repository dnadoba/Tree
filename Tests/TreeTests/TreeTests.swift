import XCTest
@testable import Tree

final class TreeTests: XCTestCase {
    func testExample() {
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
}
